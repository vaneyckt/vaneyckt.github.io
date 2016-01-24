+++
date = "2015-12-19T19:20:03+00:00"
title = "The disaster that is Ruby's timeout method"
type = "post"
ogtype = "article"
topics = [ "ruby" ]
+++

On paper, [Ruby's timeout method](http://ruby-doc.org/stdlib-2.1.1/libdoc/timeout/rdoc/Timeout.html#method-c-timeout) looks like an incredibly useful piece of code. Ever had a network request occasionally slow down your entire program because it just wouldn't finish? That's where `timeout` comes in. It provides a hard guarantee that a block of code will be finished within a specified amount of time.

```ruby
require 'timeout'

timeout(5) do
  # block of code that should be interrupted if it takes more than 5 seconds
end
```

There's one thing the documentation doesn't tell you though. If any of the lines in that block of code introduces side effects that rely on the execution of later lines of code to leave things in a stable state, then using the `timeout` method is a great way to introduce instability in your program. Examples of this include pretty much any program that is not entirely without stateful information. Let's have a closer look at this method to try and figure out what's going on here exactly.

### Exceptions absolutely anywhere

The problem with `timeout` is that it relies upon Ruby's questionable ability to have one thread raise an exception *absolutely anywhere* in an entirely different thread. The idea is that when you place code inside a `timeout` block, this code gets wrapped inside a new thread that executes in the background while the main thread goes to sleep for 5 seconds. Upon waking, the main thread grabs the background thread and forcefully stops it by raising an exception on it ([actual implementation](https://github.com/ruby/ruby/blob/trunk/lib/timeout.rb#L72-L110)).

```ruby
# raising_exceptions.rb
# threads can raise exceptions in other threads
thr = Thread.new do
  puts '...initializing resource'
  sleep 1

  puts '...using resource'
  sleep 1

  puts '...cleaning resource'
  sleep 1
end

sleep 1.5
thr.raise('raising an exception in the thread')
```

```bash
$ ruby raising_exeptions.rb

...initializing resource
...using resource
```

The problem with this approach is that the main thread does not care what code the background thread is executing when it raises the exception. This means that the engineer responsible for the code that gets executed by the background thread needs to assume an exception can get thrown from *absolutely anywhere* within her code. This is madness! No one can be expected to place exception catchers around every single block of code!

The following code further illustrates the problem of being able to raise an exception *absolutely anywhere*. Turns out that *absolutely anywhere* includes locations like the inside of `ensure` blocks. These locations are generally not designed for handling any exceptions at all. I hope you weren't using an `ensure` block to terminate your database connection!

```ruby
# ensure_block.rb
# raising exceptions inside an ensure block of another thread
# note how we never finish cleaning the resource here
thr = Thread.new do
  begin
    puts '...initializing resource'
    sleep 1

    raise 'something went wrong'

    puts '...using resource'
    sleep 1
  ensure
    puts '...started cleaning resource'
    sleep 1
    puts '...finished cleaning resource'
  end
end

sleep 1.5
thr.raise('raising an exception in the thread')

# prevent program from immediately terminating after raising exception
sleep 5
```

```bash
$ ruby ensure_blocks.rb

...initializing resource
...started cleaning resource
```

### Real world example

Recently, I spent a lot of time working with the [curb http client](https://github.com/taf2/curb). I ended up wrapping quite a few of my curb calls within `timeout` blocks because of tight time constraints. However, this caused great instability within the system I was working on. Sometimes a call would work, whereas other times that very same call would throw an exception about an invalid handle. It was this that caused me to start investigating the `timeout` method.

After having a bit of think, I came up with a proof of concept that showed beyond a doubt that the `timeout` method was introducing instability in the very internals of my http client. The finished proof of concept code can look a bit complex, so rather than showing the final concept code straightaway, I'll run you through my thought process instead.

Let's start with the basics and write some code that uses the http client to fetch a random google page. A randomized parameter is added to the google url in order to circumvent any client-side caching. The page fetch itself is wrapped inside a `timeout` block as we are interested in testing whether the `timeout` method is corrupting the http client.

```ruby
# basics.rb
# timeout doesn't get triggered
require 'curb'
require 'timeout'

timeout(1) do
  Curl.get("http://www.google.com?foo=#{rand}")
end
```

This code will rarely timeout as a page fetch generally takes way less than one second to complete. This is why we're going to wrap our page fetch inside an infinite while loop.

```ruby
# infinite_loop.rb
# timeout gets triggered and Timeout::Error exception gets thrown
require 'curb'
require 'timeout'

timeout(1) do
  while true
    Curl.get("http://www.google.com?foo=#{rand}")
  end
end
```

```bash
$ ruby infinite_loop.rb

/Users/vaneyckt/.rvm/gems/ruby-2.0.0-p594/gems/curb-0.8.8/lib/curl/easy.rb:68:
  in 'perform': execution expired (Timeout::Error)
```

The above code is now timing out and throwing a `Timeout::Error` exception. Next we want to determine whether the timing out of a page fetch could corrupt the internal state of the http client, thereby causing problems for a subsequent page fetch. We'll need to make lots of page fetches to test this, so we're going to wrap all of our current code inside another infinite while loop. Furthermore, we don't want any `Timeout::Error` exceptions to break us out of this while loop, so we're going to catch and ignore these exceptions inside the while loop we just created. This gives us our finished proof of concept code.

```ruby
# proof_of_concept.rb
# timeout corrupts the very internals of the curb http client
require 'curb'
require 'timeout'

while true
  begin
    timeout(1) do
      while true
        Curl.get("http://www.google.com?foo=#{rand}")
      end
    end
  rescue Timeout::Error => e
  end
end
```

```bash
$ ruby proof_of_concept.rb

/Users/vaneyckt/.rvm/gems/ruby-2.0.0-p594/gems/curb-0.8.8/lib/curl/easy.rb:67:
  in 'add': CURLError: The easy handle is already added to a multi handle
  (Curl::Err::MultiAddedAlready)
```

Running the above program will result in an exception being thrown after a few seconds. At some point, the `timeout` method is causing a `Timeout::Error` exception to be raised inside a critical code path of the http client. This badly timed `Timeout::Error` exception leaves the client in an invalid state, which in turn causes the next page fetch to fail with the exception shown above. Hopefully this illustrates why you should avoid creating programs that can have `Timeout::Error` exceptions pop up *absolutely anywhere*.

### Conclusion

I hope this has convinced you there is nothing you can do to prevent `timeout` from doing whatever it wants to your program's internal state. There is just no way a program can deal with `Timeout::Error` exceptions being able to potentially pop up *absolutely anywhere*. The only time you can really get away with using timeouts is when writing functional code that does not rely on any state. In all other cases, it is best to just avoid timeouts entirely.

+++
date = "2018-02-12T10:21:34+00:00"
title = "Ruby concurrency: building a timeout queue"
type = "post"
ogtype = "article"
topics = [ "ruby" ]
+++

Ruby's built-in `Queue` class is an incredibly handy data structure for all kinds of problems. Its versatility can be attributed to its `pop` method, which can be used in both a blocking and a non-blocking manner. However, when using a blocking `pop`, you may not always want to run the risk of this `pop` potentially blocking indefinitely. Instead, you might wish for your `pop` to block only until a given timeout interval has expired, after which it'll throw an exception. We'll refer to a queue that supports such `pop` behavior as a `TimeoutQueue`. This post will show you how to build such a queue.

### Setting the stage

Going forward, I'll assume you're comfortable with all the concepts introduced in [my earlier post on condition variables](https://vaneyckt.io/posts/ruby_concurrency_in_praise_of_condition_variables/). Our starting point will be the `SimpleQueue` implementation that we wrote as part of that post. The code for this is shown below. If some of its concepts are unfamiliar to you, then I'd highly recommend reading my earlier post before continuing on.

```ruby
class SimpleQueue
  def initialize
    @elems = []
    @mutex = Mutex.new
    @cond_var = ConditionVariable.new
  end

  def <<(elem)
    @mutex.synchronize do
      @elems << elem
      @cond_var.signal
    end
  end

  def pop(blocking = true)
    @mutex.synchronize do
      if blocking
        while @elems.empty?
          @cond_var.wait(@mutex)
        end
      end
      raise ThreadError, 'queue empty' if @elems.empty?
      @elems.shift
    end
  end
end
```

This `SimpleQueue` class behaves very similarly to Ruby's built-in `Queue` class:

- a non-blocking `pop` called on a non-empty queue will return immediately
- a non-blocking `pop` called on an empty queue will raise a `ThreadError`
- a blocking `pop` called on a non-empty queue will return immediately
- a blocking `pop` called on an empty queue will wait for data to arrive before returning

It is the scenario described by the last of these four bullet points that we want to improve upon. In its current implementation, a blocking `pop` called on an empty queue will block for as long as the queue remains empty. As there is no guarantee that the queue will ever receive data, this could be a very long time indeed. In order to prevent such indefinite waits from occurring, we are going to add timeout functionality to this blocking `pop`.

Before moving on to the next section, let's write a bit of code to prove that the four bullet points above do, in fact, hold true for our `SimpleQueue` implementation.

```ruby
simple_queue = SimpleQueue.new

# non-blocking pop, non-empty queue
simple_queue << 'foobar'
simple_queue.pop(false) # => immediately returns 'foobar'

# non-blocking pop, empty queue
simple_queue.pop(false) # => immediately raises a ThreadError exception

# blocking pop, non-empty queue
simple_queue << 'foobar'
simple_queue.pop # => immediately returns 'foobar'

# blocking pop, empty queue - new data is added after 5s
Thread.new { sleep 5; simple_queue << 'foobar' }
simple_queue.pop # => waits for 5s for data to arrive, then returns 'foobar'
```

At this point, we can rest assured that our `SimpleQueue` class does indeed behave like Ruby's built-in `Queue` class. Now let's continue on to the next section where we'll start adding timeout functionality to the blocking `pop` method.

### A first attempt at adding timeout functionality

The next few sections will focus exclusively on improving the `pop` method code shown below. We'll see how we can add timeout functionality to this method with just a few well-chosen lines of code.

```ruby
def pop(blocking = true)
  @mutex.synchronize do
    if blocking
      while @elems.empty?
        @cond_var.wait(@mutex)
      end
    end
    raise ThreadError, 'queue empty' if @elems.empty?
    @elems.shift
  end
end
```

A first attempt at introducing timeout functionality could see us start by scrolling through [Ruby's condition variable documentation](http://ruby-doc.org/stdlib-2.0.0/libdoc/thread/rdoc/ConditionVariable.html). Doing so, we might spot that the `wait` method can take an optional `timeout` parameter that will cause this method to return if it is still waiting after `timeout` seconds have passed.

>*wait(mutex, timeout = nil)*

>Releases the lock held in mutex and waits; reacquires the lock on wakeup.
If timeout is given, this method returns after timeout seconds passed, even if no other thread doesn’t signal.

This could cause us to decide that we'd just need to modify our `pop` method to make use of this timeout functionality. Our code would then probably end up looking something like the snippet shown below.

```ruby
def pop(blocking = true, timeout = nil)
  @mutex.synchronize do
    if blocking
      while @elems.empty?
        @cond_var.wait(@mutex, timeout)
      end
    end
    raise ThreadError, 'queue empty' if @elems.empty?
    @elems.shift
  end
end
```

This code allows for the user to pass a `timeout` parameter to the `pop` method. This value will then get used by our condition variable's `wait` method. Seems pretty easy, right? Let's write some Ruby code to test whether the above code will allow a blocking `pop` method to timeout when called on an empty queue.

```ruby
timeout_queue = TimeoutQueue.new

# blocking pop, empty queue - new data is added after 5s
Thread.new { sleep 5; timeout_queue << 'foobar' }
timeout_queue.pop # => waits for 5s for data to arrive, then returns 'foobar'

# blocking pop, empty queue - no new data is added
timeout_queue.pop(true, 10) # => blocks indefinitely - something is wrong!
```

Our `timeout` parameter seems to have had no effect whatsoever. Instead of timing out, our blocking `pop` will still wait indefinitely for new data to arrive. What's happening here is that `@cond_var.wait(@mutex, timeout)` will indeed return after its timeout interval has passed. However, keep in mind that this statement lives inside the `while @elems.empty?` loop.

What'll happen is that `@cond_var.wait(@mutex, timeout)` will return after ten seconds. At this point, the loop's predicate will be re-evaluated. If the queue has remained empty, then the loop will repeat for another iteration from which it'll return after another ten seconds. As you can see, we're stuck in an infinite loop of 10-second intervals that we'll only be able to break out of once some data gets added to the queue. It looks like we'll have to come up with a better approach if we want our blocking `pop` to timeout correctly.

### How not to improve upon our first attempt

At first glance, it might seem reasonable to infer that the above approach's poor behavior is solely due to the presence of the `while @elems.empty?` loop. As such, one might conclude that the best way to improve this behavior would involve replacing our `while` loop with an `if` statement. The resulting code would then look something like this.

```ruby
def pop(blocking = true, timeout = nil)
  @mutex.synchronize do
    if blocking
      if @elems.empty?
        @cond_var.wait(@mutex, timeout)
      end
    end
    raise ThreadError, 'queue empty' if @elems.empty?
    @elems.shift
  end
end
```

Let's see what happens when we use this implementation and run it against the Ruby code snippet that we produced earlier.

```ruby
timeout_queue = TimeoutQueue.new

# blocking pop, empty queue - new data is added after 5s
Thread.new { sleep 5; timeout_queue << 'foobar' }
timeout_queue.pop # => waits for 5s for data to arrive, then returns 'foobar'

# blocking pop, empty queue - no new data is added
timeout_queue.pop(true, 10) # => raises ThreadError after 10s
```

Our new approach seems to work pretty well. However, replacing our `while` loop with an `if` statement is just about the worst thing we could do. As I've mentioned in great detail in [my earlier post](https://vaneyckt.io/posts/ruby_concurrency_in_praise_of_condition_variables/), using an `if` statement not only introduces a subtle race condition, but it also makes our code no longer impervious to spurious wakeups.

The race condition story is a bit too long to repeat here. However, I'll try to briefly readdress the topic of spurious wakeups. Spurious wakeups occur when a condition variable is woken up out of its `wait` state for no reason. This illustrious behavior is due to the [POSIX library's implementation of condition variables](https://en.wikipedia.org/wiki/Spurious_wakeup). As such, this is not something we can easily control. This is why we'll need to ensure that any code we write will behave correctly in the face of any such wakeups occurring.

Knowing what we know now, let's look back at the code we wrote earlier. Imagine that a spurious wakeup were to occur immediately after our condition variable entered its `wait` state. If our code were to be using an `if` statement, then such a wakeup could instantly cause a `ThreadError` to be raised. This is not what we want! We only want a `ThreadError` to be raised after the timeout interval has expired!

### Adding timeout functionality the right way

In this section, we'll see how we can correctly implement timeout functionality. Up until now, we've been trying to have our one `pop` method handle the two possible scenarios of the user specifying a timeout interval, as well as that of the user not specifying a timeout interval. While it's possible for us to continue this trend, the resulting logic will be unusually complex. For simplicity's sake, we'll create a new `pop_with_timeout` method that we'll use to explain the scenario where a timeout interval was specified.

Our goal will be to improve on the code shown below. Notice that this code is pretty much identical to the code we covered in the previous section. The only real difference is that the `timeout` parameter no longer defaults to `nil`. Instead, we now expect the user to always provide a positive value for this parameter.

```ruby
def pop_with_timeout(blocking = true, timeout)
  @mutex.synchronize do
    if blocking
      while @elems.empty?
        @cond_var.wait(@mutex, timeout)
      end
    end
    raise ThreadError, 'queue empty' if @elems.empty?
    @elems.shift
  end
end
```

Thinking back to the previous section, one of the problems with our approach is the value of `timeout` in `@cond_var.wait(@mutex, timeout)`. If we could get this value to decrease as time passes, then our code would be resistant to spurious wakeups. For example, if our condition variable were to be spuriously awoken after just 4 seconds into a 10-second timeout interval, then the next iteration of the `while` loop should cause our condition variable to re-enter its `wait` state for 6 seconds.

First of all, if we want the value passed to `@cond_var.wait` to decrease as time goes by, then we should start by storing when `@cond_var.wait` gets called. So let's introduce a `start_time` variable that does this.

```ruby
def pop_with_timeout(blocking = true, timeout)
  @mutex.synchronize do
    if blocking
      start_time = Time.now.to_f

      while @elems.empty?
        @cond_var.wait(@mutex, timeout)
      end
    end
    raise ThreadError, 'queue empty' if @elems.empty?
    @elems.shift
  end
end
```

Next up, we want to start decreasing the timeout value passed to `@cond_var.wait`. Keep in mind that Ruby will raise an exception if this value were to be negative. So we should also add some logic that prevents this from happening.

```ruby
def pop_with_timeout(blocking = true, timeout)
  @mutex.synchronize do
    if blocking
      start_time = Time.now.to_f

      while @elems.empty?
        remaining_time = (start_time + timeout) - Time.now.to_f

        if remaining_time > 0
          @cond_var.wait(@mutex, remaining_time)
        end
      end
    end
    raise ThreadError, 'queue empty' if @elems.empty?
    @elems.shift
  end
end
```

Our code is starting to look pretty good. We've introduced a new `remaining_time` variable to help us keep track of the time remaining in our timeout interval. By recalculating this variable with every iteration of our `while` loop, we ensure that its value decreases as time passes. So if a spurious wakeup were to prematurely awaken our condition variable, then the next iteration of our `while` loop would put it to sleep again for an appropriate amount of time.

Unfortunately, this code has an annoying shortcoming in that it doesn't break free from the `while @elems.empty?` loop once the timeout interval has expired. Right now, this loop will keep repeating itself until the queue is no longer empty. What we really want is for us to escape from this loop once our queue is no longer empty OR our `remaining_time` value becomes zero or less. Luckily, this is quite straightforward to solve.

```ruby
def pop_with_timeout(blocking = true, timeout)
  @mutex.synchronize do
    if blocking
      start_time = Time.now.to_f

      while @elems.empty? && (remaining_time = (start_time + timeout) - Time.now.to_f) > 0
        @cond_var.wait(@mutex, remaining_time)
      end
    end
    raise ThreadError, 'queue empty' if @elems.empty?
    @elems.shift
  end
end
```

We can write the above approach slightly more succinctly by replacing `start_time` with `timeout_time`. This gives us our final `pop_with_timeout` code shown here.

```ruby
def pop_with_timeout(blocking = true, timeout)
  @mutex.synchronize do
    if blocking
      timeout_time = Time.now.to_f + timeout

      while @elems.empty? && (remaining_time = timeout_time - Time.now.to_f) > 0
        @cond_var.wait(@mutex, remaining_time)
      end
    end
    raise ThreadError, 'queue empty' if @elems.empty?
    @elems.shift
  end
end
```

The final `TimeoutQueue` class is shown below. The `pop_with_timeout` logic has been put inside the regular `pop` method in order to minimize code duplication. It should be pretty easy to recognize the bits and pieces that we've covered as part of this article.

```ruby
class TimeoutQueue
  def initialize
    @elems = []
    @mutex = Mutex.new
    @cond_var = ConditionVariable.new
  end

  def <<(elem)
    @mutex.synchronize do
      @elems << elem
      @cond_var.signal
    end
  end

  def pop(blocking = true, timeout = nil)
    @mutex.synchronize do
      if blocking
        if timeout.nil?
          while @elems.empty?
            @cond_var.wait(@mutex)
          end
        else
          timeout_time = Time.now.to_f + timeout
          while @elems.empty? && (remaining_time = timeout_time - Time.now.to_f) > 0
            @cond_var.wait(@mutex, remaining_time)
          end
        end
      end
      raise ThreadError, 'queue empty' if @elems.empty?
      @elems.shift
    end
  end
end
```

Let's see how our `TimeoutQueue` fares when we plug it into our trusty Ruby snippet.

```ruby
timeout_queue = TimeoutQueue.new

# blocking pop, empty queue - new data is added after 5s
Thread.new { sleep 5; timeout_queue << 'foobar' }
timeout_queue.pop # => waits for 5s for data to arrive, then returns 'foobar'

# blocking pop, empty queue - no new data is added
timeout_queue.pop(true, 10) # => raises ThreadError after 10s
```

This is exactly the behavior that we want. This is the same behavior we saw back when we replaced our `while` loop with an `if` statement. However, this time around our queue will behave correctly in the face of spurious wakeups. That is to say, if our condition variable were to be woken up early, then our `while` loop would ensure it is put back to sleep again. This `while` loop also protects us from a subtle race condition that would have otherwise been introduced if we had used an `if` statement instead. More information about this race condition can be found in [one of my earlier posts](https://vaneyckt.io/posts/ruby_concurrency_in_praise_of_condition_variables/). We have now successfully created a fully functioning `TimeoutQueue` class!

### Conclusion

I hope this article has been helpful for those wanting to add timeout functionality to their Ruby queues. Condition variables are a notoriously poorly documented subject in Ruby, and hopefully, this post goes some way towards alleviating this. I also want to give a shout-out to Job Vranish whose [two](https://spin.atomicobject.com/2014/07/07/ruby-queue-pop-timeout/) [posts](https://spin.atomicobject.com/2017/06/28/queue-pop-with-timeout-fixed/) on condition variables got me to start learning more about them well over a year ago.

Let me just put up my usual disclaimer stating that while everything mentioned above is correct to the best of my knowledge, I’m unable to guarantee that absolutely no mistakes snuck in while writing this. As always, please feel free to contact me with any corrections.

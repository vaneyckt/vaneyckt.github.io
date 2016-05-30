+++
date = "2016-03-17T19:12:21+00:00"
title = "Ruby concurrency: in praise of the mutex"
type = "post"
ogtype = "article"
topics = [ "ruby" ]
+++

When reading about Ruby you will inevitably be introduced to the Global Interpreter Lock. This mechanism tends to come up in explanations of why Ruby threads run concurrently on a single core, rather than being scheduled across multiple cores in true parallel fashion. This single core scheduling approach also explains why adding threads to a Ruby program does not necessarily result in faster execution times.

This post will start by explaining some of the details behind the GIL. Next up, we'll be taking a look at the three crucial concepts of concurrency: atomicity, visibility, and ordering. While most developers are familiar with atomicity, the concept of visibility is often poorly understood. We'll be going over each of these concepts in quite some detail and will illustrate how to address their needs through correct usage of the mutex data structure.

### Parallelism and the GIL

Ruby's Global Interpreter Lock is a global lock around the execution of Ruby code. Before a Ruby thread can execute any code, it first needs to acquire this lock. A thread holding the GIL will be forced to release it after a certain amount of time, at which point the kernel can hand the GIL to another Ruby thread. As the GIL can only be held by one thread at a time, it effectively prevents two Ruby threads from being executed at the same time.

Luckily, Ruby comes with an optimization that forces a thread to let go of the GIL when waiting on blocking IO. Such a thread will use the [ppoll system call](http://linux.die.net/man/2/ppoll) to be notified when its blocking IO has finished. Only then will the thread try to reacquire the GIL again. This type of behavior holds true for all blocking IO calls, as well as backtick and system calls. So even with the GIL, Ruby is still able to have moments of true parallelism.

Note that the GIL is specific to the default Ruby interpreter ([MRI](https://en.wikipedia.org/wiki/Ruby_MRI)) which relies on a global lock to protect its internals from race conditions. The GIL also makes it possible to safely interface the MRI interpreter with C libraries that may not be thread-safe themselves. Other interpreters have taken different approaches to the concept of a global lock; [Rubinius](http://rubinius.com/) opts for a collection of fine-grained locks instead of a single global one, whereas [JRuby](http://jruby.org/) does not use global locking at all.

Now that we understand the effects of the GIL with regards to Ruby's concurrency, let us move on to studying the pivotal role of the mutex data structure in writing correct concurrent code.

### Mutex

There are three crucial concepts to concurrency: atomicity, visibility, and ordering. We'll be taking a look at how we can use Ruby's mutex data structure to address these. Keep in mind that different languages tackle these concepts in different ways. As such, the mutex-centric approach described here is only guaranteed to work in Ruby.

#### Atomicity

Atomicity is probably the best-known concurrency concept. A section of code is atomic if its operations cannot be interrupted halfway through by other threads. This means that if a thread were to atomically modify the state of a shared object, then other threads wouldn't be able to see any of the intermediate states of that object. These other threads either see the state as it was before the operation, or they see the state as it is after the operation. They cannot see any of the intermediate states created during the operation!

In the example below we have created a `counters` array that holds ten entries set to zero. This array represents an object that we want to modify, and its ten entries represent its internal state. Let's say we have five threads, each of which runs a loop for 100.000 iterations that increments every entry by one. Intuitively we'd expect the output of this to be an array where each entry is 500.000. However, as we can see, this is not the case.

```ruby
# atomicity.rb
counters = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

threads = 5.times.map do
  Thread.new do
    100000.times do
      counters.map! { |counter| counter + 1 }
    end
  end
end
threads.each(&:join)

puts counters.to_s
# => [500000, 447205, 500000, 500000, 500000, 500000, 203656, 500000, 500000, 500000]
```

The reason for this unexpected output is that `counters.map! { |counter| counter + 1 }` is not atomic. For example, imagine that our first thread has just read the value of the first entry, incremented it by one, and is now getting ready to write this incremented value to the first entry of our array. However, before our thread can write this incremented value, it gets interrupted by the second thread. This second thread then goes on to read the current value of the first entry, increments it by one, and - unlike the first thread - succeeds in writing the result back to the first entry of our array. Now we have a problem!

We have a problem because the first thread got interrupted before it had a chance to write its incremented value to the array. When the first thread resumes, it will end up overwriting the value that the second thread just placed in the array. This will cause us to essentially lose an increment operation, which explains why our program output has entries in it that are less than 500.000. It should hopefully be clear that none of this would have happened if we guaranteed that `counters.map! { |counter| counter + 1 }` was atomic, and therefore uninterruptible. Luckily we can do exactly this by using a mutex.

```ruby
# atomicity.rb
mutex = Mutex.new
counters = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

threads = 5.times.map do
  Thread.new do
    100000.times do
      mutex.synchronize do
        counters.map! { |counter| counter + 1 }
      end
    end
  end
end
threads.each(&:join)

puts counters.to_s
# => [500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000]
```

Atomicity can be accomplished by using a mutex as a locking mechanism that ensures no two threads can simultaneously execute the same section of code. The snippet above shows how we can ensure that a thread executing `counters.map! { |counter| counter + 1 }` will not be interrupted by other threads. The atomicity of this section of code is guaranteed by us using `mutex.synchronize`. A mutex guarantees exclusive access to a critical section of code!

#### Visibility

Visibility determines when the results of the actions performed by a thread become visible to other threads. For example, when a thread wants to write an updated value to memory, that updated value may end up being put in a cache for a while until the kernel decides to flush it to main memory. Other threads accessing that memory will therefore end up getting a stale value!

The code below shows an example of the visibility problem. Here we have a bunch of threads flipping the boolean values in the `flags` array over and over again. Since the code switching these values is wrapped inside a mutex, we know for sure this section of code is uninterruptible. We would thus expect the output of this program to always contain the same boolean value for every entry of this array. However, we shall soon see that this does not hold true.

```ruby
# visibility.rb
mutex = Mutex.new
flags = [false, false, false, false, false, false, false, false, false, false]

threads = 50.times.map do
  Thread.new do
    100000.times do
      puts flags.to_s
      mutex.synchronize do
        flags.map! { |f| !f }
      end
    end
  end
end
threads.each(&:join)
```

```bash
$ ruby visibility.rb > visibility.log
$ grep -Hnri 'true, false' visibility.log | wc -l
    30
```

This code will produce five million lines of output. We'll use the `>` operator to write all these lines to a file. Having done this, we can then `grep` for inconsistencies in the output. We would expect every line of the output to contain an array with all its entries set to the same boolean value. However, it turns out that this only holds true for 99.9994% of all lines. Sometimes the flipped boolean values don't get written back to memory fast enough, causing other threads to read stale data. We have caught the visibility problem in action!

Luckily we can solve this problem by using a [memory barrier](https://en.wikipedia.org/wiki/Memory_barrier). A memory barrier enforces an ordering constraint on memory operations so as to prevent the possibility of reading stale data. In Ruby, a mutex not only acts as an atomic lock, but also functions as a memory barrier. All we need to do is ensure that if we use a mutex when writing to a variable, we use this same mutex when reading from that variable as well.

```ruby
# visibility.rb
mutex = Mutex.new
flags = [false, false, false, false, false, false, false, false, false, false]

threads = 50.times.map do
  Thread.new do
    100000.times do
      mutex.synchronize do
        puts flags.to_s
      end
      mutex.synchronize do
        flags.map! { |f| !f }
      end
    end
  end
end
threads.each(&:join)
```

```bash
$ ruby visibility.rb > visibility.log
$ grep -Hnri 'true, false' visibility.log | wc -l
    0
```

As expected, this time we found zero inconsistencies in the output data due to us using the same mutex for both reading and writing the boolean values of the `flags` array. Do keep in mind that not all languages allow for using a mutex as a memory barrier, so be sure to check the specifics of your favorite language before going off to write concurrent code.

### Ordering

As if dealing with visibility isn't hard enough, the Ruby interpreter is also allowed to change the order of the instructions in your code in an attempt at optimization. Before I continue I should point out that there is no official specification for the Ruby language. This can make it hard to find information about topics such as this. So I'm just going to describe how I _think_ instruction reordering currently works in Ruby.

Your Ruby code gets compiled to bytecode by the Ruby interpreter. The interpreter is free to reorder your code in an attempt to optimize it. This bytecode will then generate a set of CPU instructions, which [the CPU is free to reorder](https://en.wikipedia.org/wiki/Out-of-order_execution) as well. I wasn't able to come up with example code that actually showcases this reordering behavior, so this next bit is going to be somewhat hand-wavy. Let's say we were given the code shown below (which I got from [here](http://jeremymanson.blogspot.ie/2007/08/atomicity-visibility-and-ordering.html)).

```ruby
# ordering.rb
a = false
b = false
threads = []

thr1 = Thread.new do
  a = true
  b = true
end

thr2 = Thread.new do
  r1 = b # could see true
  r2 = a # could see false
  r3 = a # could see true
  puts (r1 && !r2) && r3 # could print true
end

thr1.join
thr2.join
```

Since there are a lot of ways for instruction reordering to take place, it is not entirely impossible for `b = true` to be executed before `a = true`. In theory, this could therefore allow for `thr2` to end up outputting `true`. This is rather counterintuitive, as at first glance we would expect `thr2` to always output `false`.

Luckily there is no need to worry too much about this. When looking at the code above, it is hopefully obvious to you that code reordering is going to be the least of this code's problems. The absence of any kind of synchronization to deal with atomicity and visibility issues in this threaded program is going to cause way bigger headaches than code reordering ever could.

The above-mentioned synchronization issues can be fixed by using a mutex. By introducing a mutex we are explicitly telling the interpreter and CPU how we want our code to behave, which in turn will prevent any problematic code reordering from occurring. Dealing with atomicity and visibility issues will therefore implicitly prevent any dangerous code reordering.

### Conclusion

I hope this post has helped show just how easy it can be to introduce bugs in concurrent code. In my experience, the concept of memory barriers is often poorly understood, which can result in introducing some incredibly hard to find bugs. Luckily, as we saw in this post, the mutex data structure can be a veritable panacea for addressing these issues in Ruby.

Please feel free to contact me if you think I got anything wrong. While all of the above is correct to the best of my knowledge, the lack of an official Ruby specification can make it hard to locate information that is definitively without error.

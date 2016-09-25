+++
date = "2016-05-17T19:12:21+00:00"
title = "Ruby concurrency: condition variables and monitors"
type = "post"
ogtype = "article"
topics = [ "ruby" ]
+++


example:

20 threads writing to a queue.. point out that queue is threadsafe by nature
when more than 10 elements are in there, we signal the cv

question: is there a guarantee that a cond.sigal will cause the very next thread to run to be the cond.wait thread? Or could it be another thread?

what if the order goes like this

- signal
- signal
- consumer thread gets resumed

will the second signal wake up a different consumer thread?
can I use this as an intro to explain why cond.wait should be surrounded with a while statement?



### Condition variable

problems solved by condition variable:
- Condition variable: mutex is about exlusive access to a critical section, whereas condition variable is about inter-thread communication by putting threads to sleep and waking them back up once a certain condition is met. Condition variables always need to be used in conjunction with mutexes. e.g. a thread can go to sleep, another thread can prepare some work, and then wake up the first thread by signaling it with a condition variable. If we did't do it like this, then the sleepy thread would have to keep polling for work all the time.

conditionvariable.signal is used to wake up a waiting (sleepy) thread
condvar.wait(mutex) needs to receive a locked mutex - wait unlocks the mutex and pits the thread to sleep
signal vs broadcast

do cond varrs always need to be inside a mutex sync block?
does cond ar .signal only trigger after it has finished the sync block? or does it trigger during the sync block?

mutexes are smart so as to ensure no two threads can modify a CV at the same time

mutex (mutual exclusion) forces other threads to wait. The Mutex class unsurprisingly has a method called synchronize.
condition variable is a way to avoid busy-waiting. It allows a thread to go to sleep and be woken up by a signal. It’s always used in conjunction with a mutex.
monitor is a re-entrant mutex that’s shared across multiple methods often in an object. eg the synchronize keyword in Java. There is a Monitor class in ruby, and it’s useful for ADT style objects, ie stacks, lists, things like that where you have multiple ways of accessing shared state, that must remain consistent, ie not have race conditions. But, it’s quite coarse-grained because it basically locks the whole object.

Condition variable is also badly named. It’s easier to think of it as fifo list of threads (I’m deliberately not saying queue, because most implementations don’t use an actual queue, they just behave as if they do). And the condition part is actually outside the actual ConditionVariable instance. So now it’s badly named twice. It should have been called a WaitList. “Unfortunately sah, we’re full, but we’ll notify you if we have a cancellation.”

http://phrogz.net/programmingruby/tut_threads.html

require 'thread'
mutex = Mutex.new
cv = ConditionVariable.new
a = Thread.new {
  mutex.synchronize {
    puts "A: I have critical section, but will wait for cv"
    cv.wait(mutex)
    puts "A: I have critical section again! I rule!"
  }
}

puts "(Later, back at the ranch...)"

b = Thread.new {
  mutex.synchronize {
    puts "B: Now I am critical, but am done with cv"
    cv.signal
    puts "B: I am still critical, finishing up"
  }
}
a.join
b.join
produces:
A: I have critical section, but will wait for cv
(Later, back at the ranch...)

B: Now I am critical, but am done with cv
B: I am still critical, finishing up
A: I have critical section again! I rule!

condition variable as a save point (resume point)
don't forget to talk about the cv.wait(mutex, timeout)

http://web.stanford.edu/class/cs140/cgi-bin/lecture.php?topic=locks
Warning: when a thread wakes up after condition_wait there is no guarantee that the desired condition still exists: another thread might have snuck in. Seems like this is something that could happen with broadcast.


http://blog.maxaller.name/2010/10/ruby-monitor-basics-or-how-the-heck-do-i-synchronize-producersconsumers/

http://djellemah.com/blog/2015/02/09/dataflow-concurrency-ruby/
monitor is a re-entrant mutex that’s shared across multiple methods often in an object. eg the synchronize keyword in Java. There is a Monitor class in ruby, and it’s useful for ADT style objects, ie stacks, lists, things like that where you have multiple ways of accessing shared state, that must remain consistent, ie not have race conditions. But, it’s quite coarse-grained because it basically locks the whole object.



http://ruby-doc.org/stdlib-1.9.3/libdoc/monitor/rdoc/MonitorMixin.html

https://stackoverflow.com/questions/13086107/how-to-use-condition-variables
https://www.ruby-forum.com/topic/552008
https://spin.atomicobject.com/2014/07/07/ruby-queue-pop-timeout/
does calling signal() only forces a switch once the mutex is unlocked? or does the waiting var forcibly grab the mutex?
conditionvariable seem great for callback, e.g. don't return unless there is data - without having to use a lock
see p.110 of book - note that book uses loop, website uses if statement
queue is only threadsafe data structure in ruby

note that pop blocks by default - http://ruby-doc.org/stdlib-2.0.0/libdoc/thread/rdoc/Queue.html#method-i-pop
http://blog.ifyouseewendy.com/blog/2016/02/16/review-working-with-ruby-threads/
http://blog.ifyouseewendy.com/blog/2016/02/16/ruby-concurrency-article-collection/
http://ruby-doc.org/stdlib-2.1.1/libdoc/thread/rdoc/ConditionVariable.html#method-i-wait - wait has a timeout


foo foo foo

When reading about Ruby you will inevitably be introduced to the Global Interpreter Lock. This mechanism tends to come up in explanations of why Ruby threads run concurrently on a single core, rather than being scheduled across multiple cores in true parallel fashion. This single core scheduling approach also explains why adding threads to a Ruby program does not necessarily result in faster execution times.

This post will start by explaining some of the details behind the GIL. Next up, we'll take a look at the three crucial concepts of concurrency: atomicity, visibility, and ordering. While most developers are familiar with atomicity, the concept of visibility is often not very well understood. We will be going over these concepts in quite some detail and will illustrate how to address their needs through correct usage of the mutex data structure.

### Parallelism and the GIL

Ruby's Global Interpreter Lock is a global lock around the execution of Ruby code. Before a Ruby thread can execute any code, it first needs to acquire this lock. A thread holding the GIL will be forced to release it after a certain amount of time, at which point the kernel can hand the GIL to another Ruby thread. As the GIL can only be held by one thread at a time, it effectively prevents two Ruby threads from being executed at the same time.

Luckily Ruby comes with an optimization that forces threads to let go off the GIL when they find themselves waiting on blocking IO to complete. Such threads will use the [ppoll system call](http://linux.die.net/man/2/ppoll) to be notified when their blocking IO has finished. Only then will they make an attempt to reacquire the GIL again. This type of behavior holds true for all blocking IO calls, as well as backtick and system calls. So even with the Global Interpreter Lock, Ruby is still able to have moments of true parallelism.

Note that the GIL is specific to the default Ruby interpreter ([MRI](https://en.wikipedia.org/wiki/Ruby_MRI)) which relies on a global lock to protect its internals from race conditions. The GIL also makes it possible to safely interface the MRI interpreter with C libraries that may not be thread-safe themselves. Other interpreters have taken different approaches to the concept of a global lock; [Rubinius](http://rubinius.com/) opts for a collection of fine-grained locks instead of a single global one, whereas [JRuby](http://jruby.org/) does not use global locking at all.

### Concurrency and the Mutex

There are three crucial concepts to concurrency: atomicity, visibility, and ordering. We'll be taking a look at how Ruby's mutex data structure addresses these. It is worth pointing out that different languages tackle these concepts in different ways. As such, the mutex-centric approach described here is only guaranteed to work in Ruby.

#### Atomicity

Atomicity is probably the best-known concurrency concept. A section of code is said to atomically modify the state of an object if all other threads are unable to see any of the intermediate states of the object being modified. These other threads either see the state as it was before the operation, or they see the state as it is after the operation.

In the example below we have created a `counters` array that holds ten entries, each of which is set to zero. This array represents an object that we want to modify, and its entries represent its internal state. Let's say we have five threads, each of which executes a loop for 100.000 iterations that increments every entry by one. Intuitively we'd expect the output of this to be an array with each entry set to 500.000. However, as we can see below, this is not the case.

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

The reason for this unexpected output is that `counters.map! { |counter| counter + 1 }` is not atomic. For example, imagine that our first thread has just read the value of the first entry, incremented it by one, and is now getting ready to write this incremented value to the first entry of our array. However, before our thread can write this incremented value, it gets interrupted by the second thread. This second thread then goes on to read the current value of the first entry, increments it by one, and succeeds in writing the result back to the first entry of our array. Now we have a problem!

We have a problem because the first thread got interrupted before it had a chance to write its incremented value to the array. When the first thread resumes, it will end up overwriting the value that the second thread just placed in the array. This will cause us to essentially lose an increment operation, which explains why our program output has entries in it that are less than 500.000.

It should hopefully be clear that none of this would have happened if we had made sure that `counters.map! { |counter| counter + 1 }` was atomic. This would have made it impossible for the second thread to just come in and modify the intermediate state of the `counters` array.

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

Atomicity can be accomplished by using a mutex as a locking mechanism that ensures no two threads can simultaneously execute the same section of code. The code above shows how we can prevent a thread executing `counters.map! { |counter| counter + 1 }` from being interrupted by other threads wanting to execute the same code. Also, be sure to note that `mutex.synchronize` only prevents a thread from being interrupted by others wanting to execute code wrapped inside the same `mutex` variable!

#### Visibility

Visibility determines when the results of the actions performed by a thread become visible to other threads. For example, when a thread wants to write an updated value to memory, that updated value may end up being put in a cache for a while until the kernel decides to flush it to main memory. Other threads that read from that memory will therefore end up with a stale value!

The code below shows an example of the visibility problem. Here we have several threads flipping the boolean values in the `flags` array over and over again. The code responsible for changing these values is wrapped inside a mutex, so we know the intermediate states of the `flags` array won't be visible to other threads. We would thus expect the output of this program to contain the same boolean value for every entry of this array. However, we shall soon see that this does not always hold true.

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

This code will produce five million lines of output. We'll use the `>` operator to write all these lines to a file. Having done this, we can then `grep` for inconsistencies in the output. We would expect every line of the output to contain an array with all its entries set to the same boolean value. However, it turns out that this only holds true for 99.9994% of all lines. Sometimes the flipped boolean values don't get written to memory fast enough, causing other threads to read stale data. This is a great illustration of the visibility problem.

Luckily we can solve this problem by using a [memory barrier](https://en.wikipedia.org/wiki/Memory_barrier). A memory barrier enforces an ordering constraint on memory operations thereby preventing the possibility of reading stale data. In Ruby, a mutex not only acts as an atomic lock, but also functions as a memory barrier. When wanting to read the value of a variable being modified by multiple threads, a memory barrier will effectively tell your program to wait until all in-flight memory writes are complete. In practice this means that if we use a mutex when writing to a variable, we need to use this same mutex when reading from that variable as well.

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

#### Ordering

As if dealing with visibility isn't hard enough, the Ruby interpreter is also allowed to change the order of the instructions in your code in an attempt at optimization. Before I continue I should point out that there is no official specification for the Ruby language. This can make it hard to find information about topics such as this. So I'm just going to describe how I _think_ instruction reordering currently works in Ruby.

Your Ruby code gets compiled to bytecode by the Ruby interpreter. The interpreter is free to reorder your code in an attempt to optimize it. This bytecode will then generate a set of CPU instructions, which [the CPU is free to reorder](https://en.wikipedia.org/wiki/Out-of-order_execution) as well. I wasn't able to come up with example code that actually showcases this reordering behavior, so this next bit is going to be somewhat hand-wavy. Let's say we were given the code shown below ([original source](http://jeremymanson.blogspot.ie/2007/08/atomicity-visibility-and-ordering.html)).

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

Since there are a lot of ways for instruction reordering to take place, it is not impossible for `b = true` to be executed before `a = true`. In theory, this could therefore allow for `thr2` to end up outputting `true`. This is rather counterintuitive, as this would only be possible if the variable `b` had changed value before the variable `a`.

Luckily there is no need to worry too much about this. When looking at the code above, it should be obvious that code reordering is going to be the least of its problems. The lack of any kind of synchronization to help deal with atomicity and visibility issues in this threaded program is going to cause way bigger headaches than code reordering ever could.

Those synchronization issues can be fixed by using a mutex. By introducing a mutex we are explicitly telling the interpreter and CPU how our code should behave, thus preventing any problematic code reordering from occurring. Dealing with atomicity and visibility issues will therefore implicitly prevent any dangerous code reordering.

### Conclusion

I hope this post has helped show just how easy it can be to introduce bugs in concurrent code. In my experience, the concept of memory barriers is often poorly understood, which can result in introducing some incredibly hard to find bugs. Luckily, as we saw in this post, the mutex data structure can be a veritable panacea for addressing these issues in Ruby.

Please feel free to contact me if you think I got anything wrong. While all of the above is correct to the best of my knowledge, the lack of an official Ruby specification can make it hard to locate information that is definitively without error.

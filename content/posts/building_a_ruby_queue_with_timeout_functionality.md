+++
date = "2017-07-18T10:21:34+00:00"
title = "Buiding a Ruby Queue with timeout functionality"
type = "post"
ogtype = "article"
topics = [ "ruby" ]
+++

In an [earlier post](https://vaneyckt.io/posts/ruby_concurrency_in_praise_of_condition_variables/), we explained how condition variables can be used to create your own `Queue` class. This article will build further on this and show how to add a blocking `shift` method that supports timeouts to this class. This is a relatively advanced topic, and hence we will assume that the reader has a decent grasp of the intricacies of condition variables. A refresher on this topic, to which I will be referring throughout this text, can be found [here](https://vaneyckt.io/posts/ruby_concurrency_in_praise_of_condition_variables/).

### Setting the stage

Ruby's [built-in Queue class](https://ruby-doc.org/core-2.2.0/Queue.html) comes with a blocking `shift` method. Calling this method on a non-empty queue will cause the least-recent element to be removed from the queue and returned to the caller. However, when this method is called on an empty queue it will start blocking indefinitely until a new element enters the queue, which will then be removed and returned to the caller.

Wouldn't it be nice if we could prevent our `shift` method from blocking indefinitely when our queue has no elements? Perhaps by having our `shift` method take a parameter that allows us to specify a timeout window? There's a [well-known article](https://spin.atomicobject.com/2014/07/07/ruby-queue-pop-timeout/) by Job Vranish that showcases exactly that. However, as we shall see, this implementation actually has a few imperfections. The goal of this post is to first highlight and then improve on these.

Before continuing, I would like to state that I have nothing but respect for Job Vranish. I've chosen his well-known article, because in the three years since it was published, no one seems to have spotted both of its flaws. Not even the people in the comments section. If that doesn't tell you that concurrency is *hard*, and that everyone doing it will make some mistakes every now and then, I don't know what will.

 despite being well-known, no one has pointed out its flaws.

The aim of this post is to first highlight and


### Improving the blocking shift



### Improving the blocking shift with timeouts



### Conclusion



https://spin.atomicobject.com/2014/07/07/ruby-queue-pop-timeout/

I would higly recommend reading

In this article, I would like to showcase

 in that it will see use create a `Queue`. I would highly recommend reading
If you are not very comfortable using familiar with condition variables, I would highly recommend reading

 to use condition variables, as well as  showed how we could use condition variables to create our own `Queue` class. This article will build upon the topics


This is going to be a bit of an

In a previous post, we talked about the benefits conferred by [Ruby mutexes](https://vaneyckt.io/posts/ruby_concurrency_in_praise_of_the_mutex/). While a programmer's familiarity with mutexes is likely to depend on what kind of programs she usually writes, most developers tend to be at least somewhat familiar with these particular synchronization primitives. This article, however, is going to focus on a much lesser-known synchronization construct: the condition variable.

Condition variables are used for putting threads to sleep and waking them back up once a certain condition is met. Don't worry if this sounds a bit vague; we'll go into a lot more detail later. As condition variables always need to be used in conjunction with mutexes, we'll lead with a quick mutex recap. Next, we'll introduce consumer-producer problems and how to elegantly solve them with the aid of condition variables. Then, we'll have a look at how to use these synchronization primitives for implementing blocking method calls. Finishing up, we'll describe some curious condition variable behavior and how to safeguard against it.

### A mutex recap

Mutexes are usually explained as locks that are responsible for ensuring that only one thread at a time can access a particular section of code. While this definition is correct, it has always seemed a bit too mechanical to me. That is to say, it foregoes any explanation of mutexes as a concept and instead focuses wholly on implementation details. There is, however, another way of looking at these data structures.

At their core, mutexes are all about signaling when state changes made by one thread should become visible to others. That sounds super abstract, so now is probably a good time to bring in some code. The code below shows your standard "two threads trying to modify the same variable with and without mutexes" scenario used by every blog post about mutexes ever.

```ruby
def counters_with_mutex
  mutex = Mutex.new
  counters = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  5.times.map do
    Thread.new do
      100000.times do
        mutex.synchronize do
          counters.map! { |counter| counter + 1 }
        end
      end
    end
  end.each(&:join)

  counters.inspect
end

def counters_without_mutex
  counters = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  5.times.map do
    Thread.new do
      100000.times do
        counters.map! { |counter| counter + 1 }
      end
    end
  end.each(&:join)

  counters.inspect
end

puts counters_with_mutex
# => [500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000]

puts counters_without_mutex
# => [500000, 447205, 500000, 500000, 500000, 500000, 203656, 500000, 500000, 500000]
```

Surprising absolutely no one, the code that uses a mutex for dealing with multiple threads modifying the same variable produces the correct answer, whereas the other code seems to have lost some increments (more info [here](https://vaneyckt.io/posts/ruby_concurrency_in_praise_of_the_mutex/)). This is often (and quite correctly) explained as the mutex acting as a lock that ensures a second thread won't be able to write to the array that the first thread is busy modifying. This is desirable behavior as the first thread would otherwise just end up overwriting the second thread's changes, thereby making it look like some increments went missing. However, there is another way of looking at this.

From now on, forget about the locking aspects of a mutex. Going forward, think of a mutex as a construct that developers use to indicate to the interpreter which variables are being shared across multiple threads. It is this indicating of shared state that captures what a mutex is really about; the locking is just an implementation detail! Let's have a look at a few scenarios with this new point of view.

Our first scenario has three threads: two threads for incrementing the `increment_counters` array, and one thread for decrementing the `decrement_counters` array.

```ruby
threads = []
increment_mutex = Mutex.new
increment_counters = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
decrement_counters = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# we use a mutex to indicate to the interpreter that the
# increment_counters array is shared between multiple threads
threads += 2.times.map do
  Thread.new do
    100000.times do
      increment_mutex.synchronize do
        puts 'start an increment of increment_counters'
        increment_counters.map! { |counter| counter + 1 }
        puts 'finish an increment of increment_counters'
      end
    end
  end
end

# no need for a mutex here as there is only a single thread, so the
# decrement_counters array is not shared between multiple threads
threads += 1.times.map do
  Thread.new do
    100000.times do
      puts '  start a decrement of decrement_counters'
      decrement_counters.map! { |counter| counter - 1 }
      puts '  finish a decrement of decrement_counters'
    end
  end
end

threads.each(&:join)

puts increment_counters.inspect
# => [200000, 200000, 200000, 200000, 200000, 200000, 200000, 200000, 200000, 200000]

puts decrement_counters.inspect
# => [-100000, -100000, -100000, -100000, -100000, -100000, -100000, -100000, -100000, -100000]
```

If we forget everything we know about mutexes and consider them to be purely indicators of shared state, then the only thing the `increment_mutex.synchronize do` block really does is tell the interpreter that the variable `increment_counters` is shared between multiple threads. The interpreter receives this information and now knows to never interleave the first two threads with each other.

Moving on, we notice that the second half of our program has no mutex in it. This lack indicates to the interpreter that our third thread can be interleaved with any other thread without this causing any nasty side effects. It is perfectly okay for the interpreter to stop executing the critical section of the first (or second) thread halfway through and start executing the third thread instead. Our program output shows that this is indeed the case as it contains the lines shown below.

```bash
...
start an increment of increment_counters
  start a decrement of decrement_counters
  finish a decrement of decrement_counters
finish an increment of increment_counters
...
```

In essence, a mutex indicates to the interpreter what state is shared between threads. The interpreter then uses this information to decide which threads can and which threads can't be interleaved. The fact that this logic is usually implemented with some kind of locking is just an implementation detail. The important thing here is that the mutex acts a mechanism that indicates to the interpreter which threads share the same state.

While the above example may have come across as somewhat contrived, this next one seems to elude a lot of programmers that think of mutexes as just locks. Most developers think that the code shown below is without error. There's a rather pervasive misconception that a mutex is only required when writing to a shared variable, and not when reading from it. If that were true, then every line of the output of `puts flags.to_s` should consist of 10 repetitions of either `true` or `false`. As we can see below, this is not the case.

```ruby
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
$ ruby flags.rb > output.log
$ grep -Hnri 'true, false' output.log | wc -l
    30
```

However, if we think of mutexes as constructs to be used for telling the interpreter about shared state between threads, it becomes immediately obvious that the above program cannot possibly be correct. The `flags` variable is clearly being shared by multiple threads, and as such all occurrences of it should be wrapped inside a mutex.

By not wrapping `puts flags.to_s` inside the mutex, the interpreter has no way of knowing that it shouldn't interleave a thread that is executing `flags.map! { |f| !f }` with another thread wanting to execute `puts flags.to_s`. This once again showcases the power of not treating mutexes as locks but as indicators of shared state that help the interpreter decide which instructions can be safely interleaved.

### Consumer-producer problems

With that mutex refresher out of the way, we can now start looking at condition variables. Condition variables are best explained by trying to come up with a practical solution to the [consumer-producer problem](https://en.wikipedia.org/wiki/Producer-consumer_problem). In fact, consumer-producer problems are so common that Ruby already has a data structure aimed at solving these: [the Queue class](https://ruby-doc.org/core-2.3.1/Queue.html). This class uses a condition variable to implement the blocking variant of its `shift()` method. In this article, we made a conscious decision not to use the `Queue` class. Instead, we're going to write everything from scratch with the help of condition variables.

Let's have a look at the problem that we're going to solve. Imagine that we have a website where users can generate tasks of varying complexity, e.g. a service that allows users to convert uploaded jpg images to pdf. We can think of these users as producers of a steady stream of tasks of random complexity. These tasks will get stored on a backend server that has several worker processes running on it. Each worker process will grab a task, process it, and then grab the next one. These workers are our task consumers.

With what we know about mutexes, it shouldn't be too hard to write a piece of code that mimics the above scenario. It'll probably end up looking something like this.

```ruby
tasks = []
mutex = Mutex.new
threads = []

class Task
  def initialize
    @duration = rand()
  end

  def execute
    sleep @duration
  end
end

# producer threads
threads += 2.times.map do
  Thread.new do
    while true
      mutex.synchronize do
        tasks << Task.new
        puts "Added task: #{tasks.last.inspect}"
      end
      # limit task production speed
      sleep 0.5
    end
  end
end

# consumer threads
threads += 5.times.map do
  Thread.new do
    while true
      task = nil
      mutex.synchronize do
        if tasks.count > 0
          task = tasks.shift
          puts "Removed task: #{task.inspect}"
        end
      end
      # execute task outside of mutex so we don't unnecessarily
      # block other consumer threads
      task.execute unless task.nil?
    end
  end
end

threads.each(&:join)
```

The above code should be fairly straightforward. There is a `Task` class for creating tasks that take between 0 and 1 seconds to run. We have 2 producer threads, each running an endless `while` loop that safely appends a new task to the `tasks` array every 0.5 seconds with the help of a mutex. Our 5 consumer threads are also running an endless `while` loop, each iteration grabbing the mutex so as to safely check the `tasks` array for available tasks. If a consumer thread finds an available task, it removes the task from the array and starts processing it. Once the task had been processed, the thread moves on to its next iteration, thereby repeating the cycle anew.

While the above implementation seems to work just fine, it is not optimal as it requires all consumer threads to constantly poll the `tasks` array for available work. This polling does not come for free. The Ruby interpreter has to constantly schedule the consumer threads to run, thereby preempting threads that may have actual important work to do. To give an example, the above code will interleave consumer threads that are executing a task with consumer threads that just want to check for newly available tasks. This can become a real problem when there is a large number of consumer threads and only a few tasks.

If you want to see for yourself just how inefficient this approach is, you only need to modify the original code for consumer threads with the code shown below. This modified program prints well over a thousand lines of `This thread has nothing to do` for every single line of `Removed task`. Hopefully, this gives you an indication of the general wastefulness of having consumer threads constantly poll the `tasks` array.

```ruby
# modified consumer threads code
threads += 5.times.map do
  Thread.new do
    while true
      task = nil
      mutex.synchronize do
        if tasks.count > 0
          task = tasks.shift
          puts "Removed task: #{task.inspect}"
        else
          puts 'This thread has nothing to do'
        end
      end
      # execute task outside of mutex so we don't unnecessarily
      # block other consumer threads
      task.execute unless task.nil?
    end
  end
end
```

### Condition variables

So how we can create a more efficient solution to the consumer-producer problem? That is where condition variables come into play. Condition variables are used for putting threads to sleep and waking them only once a certain condition is met. Remember that our current solution to the producer-consumer problem is far from ideal because consumer threads need to constantly poll for new tasks to arrive. Things would be much more efficient if our consumer threads could go to sleep and be woken up only when a new task has arrived.

Shown below is a solution to the consumer-producer problem that makes use of condition variables. We'll talk about how this works in a second. For now though, just have a look at the code and perhaps have a go at running it. If you were to run it, you would probably see that `This thread has nothing to do` does not show up anymore. Our new approach has completely gotten rid of consumer threads busy polling the `tasks` array.

```ruby
tasks = []
mutex = Mutex.new
cond_var = ConditionVariable.new
threads = []

class Task
  def initialize
    @duration = rand()
  end

  def execute
    sleep @duration
  end
end

# producer threads
threads += 2.times.map do
  Thread.new do
    while true
      mutex.synchronize do
        tasks << Task.new
        cond_var.signal
        puts "Added task: #{tasks.last.inspect}"
      end
      # limit task production speed
      sleep 0.5
    end
  end
end

# consumer threads
threads += 5.times.map do
  Thread.new do
    while true
      task = nil
      mutex.synchronize do
        while tasks.empty?
          cond_var.wait(mutex)
        end

        if tasks.count > 0
          task = tasks.shift
          puts "Removed task: #{task.inspect}"
        else
          puts 'This thread has nothing to do'
        end
      end
      # execute task outside of mutex so we don't unnecessarily
      # block other consumer threads
      task.execute unless task.nil?
    end
  end
end

threads.each(&:join)
```

The first thing to notice is how we only had to write the five lines shown below to improve our previous solution with condition variables. Don't worry if some of the accompanying comments don't quite make sense yet. Now is also a good time to point out that the new code for both the producer and consumer threads was added inside the existing mutex synchronization blocks. Condition variables are not thread-safe and therefore always need to be used in conjunction with a mutex!

```ruby
# declaring the condition variable
cond_var = ConditionVariable.new
```

```ruby
# a producer thread now signals the condition variable
# after adding a new task to the tasks array
cond_var.signal
```

```ruby
# a consumer thread now goes to sleep when it sees that
# the tasks array is empty. It can get woken up again
# when a producer thread signals the condition variable.
while tasks.empty?
  cond_var.wait(mutex)
end
```

Let's talk about the new code now. We'll start with the consumer threads snippet. There's actually so much going on in these three lines that we'll limit ourselves to covering what `cond_var.wait(mutex)` does for now. We'll explain the need for the `while tasks.empty?` loop later. The first thing to notice about the `wait` method is the parameter that's being passed to it. Remember how a condition variable is not thread-safe and therefore should only have its methods called inside a mutex synchronization block? It is that mutex that needs to be passed as a parameter to the `wait` method.

Calling `wait` on a condition variable causes two things to happen. First of all, it causes the thread that calls `wait` to go to sleep. That is to say, the thread will tell the interpreter that it no longer wants to be scheduled. However, this thread still has ownership of the mutex as it's going to sleep. We need to ensure that the thread relinquishes this mutex because otherwise all other threads waiting for this mutex will be blocked. By passing this mutex to the `wait` method, the `wait` method internals will ensure that the mutex gets released as the thread goes to sleep.

Let's move on to the producer threads. These threads are now calling `cond_var.signal`. The `signal` method is pretty straightforward in that it wakes up exactly one of the threads that were put to sleep by the `wait` method. This newly awoken thread will indicate to the interpreter that it is ready to start getting scheduled again and then wait for its turn.

So what code does our newly awoken thread start executing once it gets scheduled again? It starts executing from where it left off. Essentially, a newly awoken thread will return from its call to `cond_var.wait(mutex)` and resume from there. Personally, I like to think of calling `wait` as creating a save point inside a thread from which work can resume once the thread gets woken up and rescheduled again. Please note that since the thread wants to resume from where it originally left off, it'll need to reacquire the mutex in order to get scheduled. This mutex reacquisition is very important, so be sure to remember it.

This segues nicely into why we need to use `while tasks.empty?` when calling `wait` in a consumer thread. When our newly awoken thread resumes execution by returning from `cond_var.wait`, the first thing it'll do is complete its previously interrupted iteration through the `while` loop, thereby evaluating `while tasks.empty?` again. This actually causes us to neatly avoid a possible race condition.

Let's say we don't use a `while` loop and use an `if` statement instead. The resulting code would then look like shown below. Unfortunately, there is a very hard to find problem with this code.

```ruby
# consumer threads
threads += 5.times.map do
  Thread.new do
    while true
      task = nil
      mutex.synchronize do
        cond_var.wait(mutex) if tasks.empty?

        if tasks.count > 0
          task = tasks.shift
          puts "Removed task: #{task.inspect}"
        else
          puts 'This thread has nothing to do'
        end
      end
      # execute task outside of mutex so we don't unnecessarily
      # block other consumer threads
      task.execute unless task.nil?
    end
  end
end
```

Imagine a scenario where we have:

- two producer threads
- one consumer thread that's awake
- four consumer threads that are asleep

A consumer thread that's awake will go back to sleep only when there are no more tasks in the `tasks` array. That is to say, a single consumer thread will keep processing tasks until no more tasks are available. Now, let's say one of our producer threads adds a new task to the currently empty `tasks` array before calling `cond_var.signal` at roughly the same time as our active consumer thread is finishing its current task. This `signal` call will awaken one of our sleeping consumer threads, which will then try to get itself scheduled. This is where a race condition is likely to happen!

We're now in a position where two consumer threads are competing for ownership of the mutex in order to get scheduled. Let's say our first consumer thread wins this competition. This thread will now go and grab the task from the `tasks` array before relinquishing the mutex. Our second consumer thread then grabs the mutex and gets to run. However, as the `tasks` array is empty now, there is nothing for this second consumer thread to work on. So this second consumer thread now has to do an entire iteration of its `while true` loop for no real purpose at all.

We can make our code more efficient by forcing each newly awakened consumer thread to check for available tasks and having it put itself to sleep again if no tasks are available. This behavior can be easily accomplished by replacing the `if tasks.empty?` statement with a `while tasks.empty?` loop. If tasks are available, a newly awoken thread will exit the loop and execute the rest of its code. However, if no tasks are found, then the loop is repeated, thereby causing the thread to put itself to sleep again by executing `cond_var.wait`. We'll see in a later section that there is yet another benefit to using this `while` loop.

### Building our own Queue class

At the beginning of a previous section, we touched on how condition variables are used by the `Queue` class to implement blocking behavior. The previous section taught us enough about condition variables for us to go and implement a basic `Queue` class ourselves. We're going to create a thread-safe `SimpleQueue` class that is capable of:

- having data appended to it with the `<<` operator
- having data retrieved from it with a non-blocking `shift` method
- having data retrieved from it with a blocking `shift` method

It's easy enough to write code that meets these first two criteria. It will probably end up looking something like the code shown below. Note that our `SimpleQueue` class is using a mutex as we want this class to be thread-safe, just like the original `Queue` class.

```ruby
class SimpleQueue
  def initialize
    @elems = []
    @mutex = Mutex.new
  end

  def <<(elem)
    @mutex.synchronize do
      @elems << elem
    end
  end

  def shift(blocking = true)
    @mutex.synchronize do
      if blocking
        raise 'yet to be implemented'
      end
      @elems.shift
    end
  end
end

simple_queue = SimpleQueue.new
simple_queue << 'foo'

simple_queue.shift(false)
# => "foo"

simple_queue.shift(false)
# => nil
```

Now let's have a look at what's needed to implement the blocking `shift` behavior. As it turns out, this is actually very easy. We only want the thread to block if the `shift` method is called when the `@elems` array is empty. This is all the information we need to determine where we need to place our condition variable's call to `wait`. Similarly, we want the thread to stop blocking once the `<<` operator appends a new element, thereby causing `@elems` to no longer be empty. This tells us exactly where we need to place our call to `signal`.

In the end, we just need to create a condition variable that makes the thread go to sleep when a blocking `shift` is called on an empty `SimpleQueue`. Likewise, the `<<` operator just needs to signal the condition variable when a new element is added, thereby causing the sleeping thread to be woken up. The takeaway from this is that blocking methods work by causing their calling thread to fall asleep. Also, please note that the call to `@cond_var.wait` takes place inside a `while @elems.empty?` loop. Always use a `while` loop when calling `wait` on a condition variable! Never use an `if` statement!

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

  def shift(blocking = true)
    @mutex.synchronize do
      if blocking
        while @elems.empty?
          @cond_var.wait(@mutex)
        end
      end
      @elems.shift
    end
  end
end

simple_queue = SimpleQueue.new

# this will print "blocking shift returned with: foo" after 5 seconds
# that is to say, the first thread will go to sleep until the second
# thread adds an element to the queue, thereby causing the first thread
# to be woken up again
threads = []
threads << Thread.new { puts "blocking shift returned with: #{simple_queue.shift}" }
threads << Thread.new { sleep 5; simple_queue << 'foo' }
threads.each(&:join)
```

One thing to point out in the above code is that `@cond_var.signal` can get called even when there are no sleeping threads around. This is a perfectly okay thing to do. In these types of scenarios calling `@cond_var.signal` will just do nothing.

### Spurious wakeups

Spurious wakeups are an impossible to avoid edge-case in condition variables. The term refers to a sleeping thread getting woken up without any `signal` call having been made. It's important to point out that this is not being caused by a bug in the Ruby interpreter or anything like that. Instead, the designers of the threading libraries used by your OS found that allowing for the occasional spurious wakeup [greatly improves the speed of condition variable operations](https://stackoverflow.com/a/8594644/1420382). As such, any code that uses condition variables needs to take spurious wakeups into account.

So does this mean that we need to rewrite all the code that we've written in this article in an attempt to make it resistant to possible bugs introduced by spurious wakeups? You'll be glad to know that this isn't the case as all code snippets in this article have always wrapped the `cond_var.wait` statement inside a `while` loop!

We covered earlier how using a `while` loop makes our code more efficient when dealing with certain race conditions as it causes a newly awakened thread to check whether there is actually anything to do for it, and if not, the thread goes back to sleep. This same `while` loop helps us deal with spurious wakeups as well.

When a thread gets woken up by a spurious wakeup and there is nothing for it to do, our usage of a `while` loop will cause the thread to detect this and go back to sleep. From the thread's point of view, being awakened by a spurious wakeup isn't any different than being woken up with no available tasks to do. So the same mechanism that helps us deal with race conditions solves our spurious wakeup problem as well. It should be obvious by now that `while` loops play a very important role when working with condition variables.

### Conclusion

Ruby's condition variables are somewhat notorious for their poor documentation. That's a shame, because they are wonderful data structures for efficiently solving a very specific set of problems. Although, as we've seen, using them isn't without pitfalls. I hope that this post will go some way towards making them (and their pitfalls) a bit better understood in the wider Ruby community.

I also feel like I should point out that while everything mentioned above is correct to the best of my knowledge, I'm unable to guarantee that absolutely no mistakes snuck in while writing this. As always, please feel free to contact me if you think I got anything wrong, or even if you just want to say hello.
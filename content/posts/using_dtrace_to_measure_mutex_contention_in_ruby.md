+++
date = "2016-10-16T21:24:12+00:00"
title = "Using DTrace to measure mutex contention in Ruby"
type = "post"
ogtype = "article"
topics = [ "ruby", "dtrace" ]
+++

I recently found myself working on Ruby code containing a sizable number of threads and mutexes. It wasn't before long that I started wishing for some tool that could tell me which particular mutexes were the most heavily contended. After all, this type of information can be worth its weight in gold when trying to diagnose why your threaded program is running slower than expected.

This is where [DTrace](http://dtrace.org/guide/preface.html) enters the picture. DTrace is a tracing framework that enables you to instrument application and system internals, thereby allowing you to measure and collect previously inaccessible metrics. Personally, I think of DTrace as black magic that allows me to gather a ridiculous amount of information about what is happening on my computer. We will see later just how fine-grained this information can get.

DTrace is available on Solaris, OS X, and FreeBSD. There is some Linux support as well, but you might be better off using one of the Linux specific alternatives instead. One of DTrace's authors has published some [helpful](http://www.brendangregg.com/dtrace.html) [articles](http://www.brendangregg.com/blog/2015-07-08/choosing-a-linux-tracer.html) about this. Please note that all the work for this particular post was done on a MacBook running OS X El Capitan (version 10.11).

### Enabling DTrace for Ruby on OS X

El Capitan comes with a new security feature called [System Integrity Protection](https://en.wikipedia.org/wiki/System_Integrity_Protection) that helps prevent malicious software from tampering with your system. Regrettably, it also prevents DTrace from working. We will need to disable SIP by following [these instructions](http://stackoverflow.com/a/33584192/1420382). Note that it is possible to only partially disable SIP, although doing so will still leave DTrace unable to attach to restricted processes. Personally, I've completely disabled SIP on my machine.

Next, we want to get DTrace working with Ruby. Although Ruby has DTrace support, there is a very good chance that your currently installed Ruby binary does not have this support enabled. This is especially likely to be true if you compiled your Ruby binary locally on an OS X system, as OS X does not allow the Ruby compilation process to access the system DTrace binary, thereby causing the resulting Ruby binary to lack DTrace functionality. More information about this can be found [here](http://stackoverflow.com/a/29232051/1420382).

I've found the easiest way to get a DTrace compatible Ruby on my system was to just go and download a precompiled Ruby binary. Naturally, we want to be a bit careful about this, as downloading random binaries from the internet is not the safest thing. Luckily, the good people over at [rvm.io](https://rvm.io/) host DTrace compatible Ruby binaries that we can safely download.

```bash
$ rvm mount -r https://rvm.io/binaries/osx/10.10/x86_64/ruby-2.2.3.tar.bz2
$ rvm use ruby-2.2.3
```

Note that if you do not wish to install rvm, and cannot find a DTrace compatible Ruby through your favorite version manager, then you could do something similar to the snippet shown below.

```bash
$ wget https://rvm.io/binaries/osx/10.11/x86_64/ruby-2.2.3.tar.bz2
$ bunzip2 ruby-2.2.3.tar.bz2
$ tar xf ruby-2.2.3.tar
$ mv ruby-2.2.3/bin/ruby /usr/local/bin/druby
$ rm -r ruby-2.2.3 ruby-2.2.3.tar
```

Running the above snippet will install a DTrace compatible Ruby on our system. Note that we rename the binary to `druby` so as to prevent conflicts with existing Ruby installations. Note that this approach should really be treated as a last resort. I strongly urge you to make the effort to find a DTrace compatible Ruby binary through your current version manager.

Now that we've ensured we'll be able to use DTrace with our installed Ruby, let's move on and start learning some DTrace basics.

### DTrace basics

DTrace is all about probes. A probe is a piece of code that fires when a specific condition is met. For example, we could ask DTrace to instrument a process with a probe that activates when the process returns from a particular system call. Such a probe would also be able to inspect the value returned by the system call made by this process.

You interact with DTrace by writing scripts in the D scripting language (not related to the D programming language). This language is a mix of C and awk, and has a very low learning curve. Below you can see an example of such a script written in D. This particular script will list all system calls being initiated on my machine along with the name of the process that initiated them. We will save this file as `syscall_entry.d`.

```C
/* syscall_entry.d */
syscall:*:*:entry
{
  printf("\tprocess_name: %s", execname);
}
```

The first line of our script tells DTrace which probes we want to use. In this particular case, we are using `syscall:*:*:entry` to match every single probe associated with initiating a system call. DTrace has individual probes for every possible system call, so if DTrace were to have no built-in functionality for matching multiple probes, I would have been forced to manually specify every single system call probe myself, and our script would have been a whole lot longer.

I want to briefly cover some DTrace terminology before continuing on. Every DTrace probe adheres to the `<provider>:<module>:<function>:<name>` description format. In the script above we asked DTrace to match all probes of the `syscall` provider that have `entry` as their name. In this particular example, we explicitly used the `*` character to show that we want to match multiple probes. However, keep in mind that the use of the `*` character is optional. Most DTrace documentation would opt for `syscall:::entry` instead.

The rest of the script is rather straightforward. We are basically just telling DTrace to print the `execname` every time a probe fires. The `execname` is a built-in DTrace variable that contains the name of the process that caused the probe to be fired. Let's go ahead and run our simple DTrace script.

```bash
$ sudo dtrace -s syscall_entry.d

dtrace: script 'syscall_entry.d' matched 500 probes
CPU     ID                    FUNCTION:NAME
  0    249                      ioctl:entry    process_name: dtrace
  0    373               gettimeofday:entry    process_name: java
  0    249                      ioctl:entry    process_name: dtrace
  0    751              psynch_cvwait:entry    process_name: java
  0    545                     sysctl:entry    process_name: dtrace
  0    545                     sysctl:entry    process_name: dtrace
  0    233                  sigaction:entry    process_name: dtrace
  0    233                  sigaction:entry    process_name: dtrace
  0    751              psynch_cvwait:entry    process_name: dtrace
  0    889                 kevent_qos:entry    process_name: Google Chrome Helper
  0    889                 kevent_qos:entry    process_name: Google Chrome Helper
  0    877           workq_kernreturn:entry    process_name: notifyd
  ...
```

The first thing to notice is that `syscall:*:*:entry` matched 500 different probes. At first glance this might seem like a lot, but on my machine there are well over 330,000 probes available. You can list all DTrace probes on your machine by running `sudo dtrace -l`.

The second thing to notice is the insane amount of data returned by DTrace. The snippet above really doesn't do the many hundreds of lines of output justice, but going forward we'll see how we can get DTrace to output just those things we are interested in.

Before moving on to the next section, I just want to note that the D scripting language is not Turing complete. It lacks such features as conditional branching and loops. DTrace is built around the ideas of minimal overhead and absolute safely. Giving people the ability to use DTrace to introduce arbitrary overhead on top of system calls does not fit with these ideas.

### Ruby and DTrace

DTrace probes have been supported by Ruby [since Ruby 2.0](https://tenderlovemaking.com/2011/12/05/profiling-rails-startup-with-dtrace.html) came out. A list of supported Ruby probes can be found [here](http://ruby-doc.org/core-2.2.3/doc/dtrace_probes_rdoc.html). Now is a good time to mention that DTrace probes come in two flavors: dynamic probes and static probes. Dynamic probes only appear in the `pid` and `fbt` probe providers. This means that the vast majority of available probes (including Ruby probes) is static.

So how exactly do dynamic and static probes differ? In order to explain this, we first need to take a closer look at just how DTrace works. When you invoke DTrace on a process you are effectively giving DTrace permission to patch additional DTrace instrumentation instructions into the process's address space. Remember how we had to disable the System Integrity Protection check in order to get DTrace to work on El Capitan? This is why.

In the case of dynamic probes, DTrace instrumentation instructions only get patched into a process when DTrace is invoked on this process. In other words, dynamic probes add zero overhead when not enabled. Static probes on the other hand have to be compiled into the binary that wants to make use of them. This is done through a [probes.d file](https://github.com/ruby/ruby/blob/trunk/probes.d).

However, even when probes have been compiled into the binary, this does not necessarily mean that they are getting triggered. When a process with static probes in its binary does not have DTrace invoked on it, any probe instructions get converted into NOP operations.
This usually introduces a negligible, but nevertheless non-zero, performance impact. More information about DTrace overhead can be found [here](http://dtrace.org/blogs/brendan/2011/02/18/dtrace-pid-provider-overhead/), [here](http://www.solarisinternals.com/wiki/index.php/DTrace_Topics_Overhead#Dynamic_Probes), and [here](http://www.solarisinternals.com/wiki/index.php/DTrace_Topics_Overhead#Static_Probes).

Now that we've immersed ourselves in all things probe-related, let's go ahead and actually list which DTrace probes are available for a Ruby process. We saw earlier that Ruby comes with static probes compiled into the Ruby binary. We can ask DTrace to list these probes for us with the following command.

```bash
$ sudo dtrace -l -m ruby -c 'ruby -v'

ID         PROVIDER       MODULE              FUNCTION      NAME
114188    ruby86029         ruby       empty_ary_alloc      array-create
114189    ruby86029         ruby               ary_new      array-create
114190    ruby86029         ruby         vm_call_cfunc      cmethod-entry
114191    ruby86029         ruby         vm_call0_body      cmethod-entry
114192    ruby86029         ruby          vm_exec_core      cmethod-entry
114193    ruby86029         ruby         vm_call_cfunc      cmethod-return
114194    ruby86029         ruby         vm_call0_body      cmethod-return
114195    ruby86029         ruby            rb_iterate      cmethod-return
114196    ruby86029         ruby          vm_exec_core      cmethod-return
114197    ruby86029         ruby       rb_require_safe      find-require-entry
114198    ruby86029         ruby       rb_require_safe      find-require-return
114199    ruby86029         ruby              gc_marks      gc-mark-begin
...
```

Let's take a moment to look at the command we entered here. We saw earlier that we can use `-l` to have DTrace list its probes. Now we also use `-m ruby` to get DTrace to limit its listing to probes from the ruby module. However, DTrace will only list its Ruby probes if you specifically tell it you are interested in invoking DTrace on a Ruby process. This is what we use `-c 'ruby -v'` for. The `-c` parameter allows us to specify a command that creates a process we want to run DTrace against. Here we are using `ruby -v` to spawn a small Ruby process in order to get DTrace to list its Ruby probes.

The above snippet doesn't actually list all Ruby probes, as the `sudo dtrace -l` command will omit any probes from the pid provider. This is because the pid provider actually defines a [class of providers](http://dtrace.org/guide/chp-pid.html), each of which gets its own set of probes depending on which process you are tracing. Each probe corresponds to an internal C function that can be called by that particular process. Below we show how to list the Ruby specific probes of this provider.

```bash
$ sudo dtrace -l -n 'pid$target:::entry' -c 'ruby -v' | grep 'ruby'

ID         PROVIDER       MODULE                     FUNCTION      NAME
1395302    pid86272         ruby                   rb_ary_eql      entry
1395303    pid86272         ruby                  rb_ary_hash      entry
1395304    pid86272         ruby                  rb_ary_aset      entry
1395305    pid86272         ruby                    rb_ary_at      entry
1395306    pid86272         ruby                 rb_ary_fetch      entry
1395307    pid86272         ruby                 rb_ary_first      entry
1395308    pid86272         ruby                rb_ary_push_m      entry
1395309    pid86272         ruby                 rb_ary_pop_m      entry
1395310    pid86272         ruby               rb_ary_shift_m      entry
1395311    pid86272         ruby                rb_ary_insert      entry
1395312    pid86272         ruby            rb_ary_each_index      entry
1395313    pid86272         ruby          rb_ary_reverse_each      entry
...
```

Here we are only listing the pid entry probes, but keep in mind that every entry probe has a corresponding pid return probe. These probes are great as they provide us with insight into which internal functions are getting called, the arguments passed to these, as well as their return values, and even the offset in the function of the return instruction (useful for when a function has multiple return instructions). Additional information about the pid provider can be found [here](http://dtrace.org/blogs/brendan/2011/02/09/dtrace-pid-provider).

### A first DTrace script for Ruby

Let us now have a look at a first DTrace script for Ruby that will tell us when a Ruby method starts and stops executing, along with the method's execution time. We will be running our DTrace script against the simple Ruby program shown below.

```ruby
# sleepy.rb
def even(rnd)
  sleep(rnd)
end

def odd(rnd)
  sleep(rnd)
end

loop do
  rnd = rand(4)
  (rnd % 2 == 0) ? even(rnd) : odd(rnd)
end
```

Our simple Ruby program is clearly not going to win any awards. It is just one endless loop, each iteration of which calls a method depending on whether a random number was even or odd. While this is obviously a very contrived example, we can nevertheless make great use of it to illustrate the power of DTrace.

```C
/* sleepy.d */
ruby$target:::method-entry
{
  self->start = timestamp;
  printf("Entering Method: class: %s, method: %s, file: %s, line: %d\n", copyinstr(arg0), copyinstr(arg1), copyinstr(arg2), arg3);
}

ruby$target:::method-return
{
  printf("Returning After: %d nanoseconds\n", (timestamp - self->start));
}
```

The above DTrace script has us using two Ruby specific DTrace probes. The `method-entry` probe fires whenever a Ruby method is entered; the `method-return` probe fires whenever a Ruby method returns. Each probe can take multiple arguments. A probe's arguments are available in the DTrace script through the `arg0`, `arg1`, `arg2` and `arg3` variables.

If we want to know what data is contained by a probe's arguments, all we have to do is look at [its documentation](http://ruby-doc.org/core-2.2.3/doc/dtrace_probes_rdoc.html#label-Declared+probes). In this particular case, we can see that the `method-entry` probe gets called by the Ruby process with exactly four arguments.

>ruby:::method-entry(classname, methodname, filename, lineno);
>
>* classname: name of the class (a string)
>* methodname: name of the method about to be executed (a string)
>* filename: the file name where the method is _being called_ (a string)
>* lineno: the line number where the method is _being called_ (an int)

The documentation tells us that `arg0` holds the class name, `arg1` holds the method name, and so on. Equally important is that the documentation tells us that the first three arguments are strings, while the fourth one is an integer. We'll need this information for when we want to print these arguments with `printf`.

You probably noticed that we are wrapping string variables inside the `copyinstr` method. The reason for this is a bit complex. When a string gets passed as an argument to a DTrace probe, we don't actually pass the entire string. Instead, we only pass the memory address where the string begins. This memory address will be specific to the address space of the Ruby process. However, DTrace probes are executed in the kernel and thus make use of a different address space than our Ruby process. In order for a probe to read a string residing in user process data, it first needs to copy this string into the kernel's address space. The `copyinstr` method is a built-in DTrace function that takes care of this copying for us.

The `self->start` notation is interesting as well. DTrace variables starting with `self->` are thread-local variables. Thread-local variables are useful when you want to tag every thread that fired a probe with some data. In our case we are using `self->start = timestamp;` to tag every thread that triggers the `method-entry` probe with a thread-local `start` variable that contains the time in nanoseconds returned by the built-in `timestamp` method.

While it is impossible for one thread to access the thread-local variables of another thread, it is perfectly possible for a given probe to access the thread-local variables that were set on the current thread by a different probe. Looking at our DTrace script, you can see that the thread-local `self->start` variable is being shared between both the `method-entry` and `method-return` probes.

Let's go ahead and run the above DTrace script on our Ruby program.

```bash
$ sudo dtrace -q -s sleepy.d -c 'ruby sleepy.rb'

Entering Method: class: RbConfig, method: expand, file: /Users/vaneyckt/.rvm/rubies/ruby-2.2.3/lib/ruby/2.2.0/x86_64-darwin14/rbconfig.rb, line: 241
Returning After: 39393 nanoseconds
Entering Method: class: RbConfig, method: expand, file: /Users/vaneyckt/.rvm/rubies/ruby-2.2.3/lib/ruby/2.2.0/x86_64-darwin14/rbconfig.rb, line: 241
Returning After: 12647 nanoseconds
Entering Method: class: RbConfig, method: expand, file: /Users/vaneyckt/.rvm/rubies/ruby-2.2.3/lib/ruby/2.2.0/x86_64-darwin14/rbconfig.rb, line: 241
Returning After: 11584 nanoseconds
...
Entering Method: class: Object, method: odd, file: sleepy.rb, line: 5
Returning After: 1003988894 nanoseconds
Entering Method: class: Object, method: odd, file: sleepy.rb, line: 5
Returning After: 1003887374 nanoseconds
Entering Method: class: Object, method: even, file: sleepy.rb, line: 1
Returning After: 15839 nanoseconds
```

It's a bit hard to convey in the snippet above, but our DTrace script is generating well over a thousand lines of output. These lines can be divided into two sections: a first section listing all the Ruby methods being called as part of the program getting ready to run, and a much smaller second section listing whether our program is calling the `even` or `odd` functions, along with the time spent in each of these function calls.

While the above output gives us a great amount of detail about what our Ruby program is doing, we really only want to gather information about the `even` and `odd` methods being called. DTrace uses predicates to make just this type of filtering possible. Predicates are `/` wrapped conditions that define whether a particular probe should be executed. The code below shows the usage of predicates to only have the `method-entry` and `method-return` probes triggered by the `even` and `odd` methods being called.

```C
/* predicates_sleepy.d */
ruby$target:::method-entry
/copyinstr(arg1) == "even" || copyinstr(arg1) == "odd"/
{
  self->start = timestamp;
  printf("Entering Method: class: %s, method: %s, file: %s, line: %d\n", copyinstr(arg0), copyinstr(arg1), copyinstr(arg2), arg3);
}

ruby$target:::method-return
/copyinstr(arg1) == "even" || copyinstr(arg1) == "odd"/
{
  printf("Returning After: %d nanoseconds\n", (timestamp - self->start));
}
```

```bash
$ sudo dtrace -q -s predicates_sleepy.d -c 'ruby sleepy.rb'

Entering Method: class: Object, method: odd, file: sleepy.rb, line: 5
Returning After: 3005086754 nanoseconds
Entering Method: class: Object, method: even, file: sleepy.rb, line: 1
Returning After: 2004313007 nanoseconds
Entering Method: class: Object, method: even, file: sleepy.rb, line: 1
Returning After: 2005076442 nanoseconds
Entering Method: class: Object, method: even, file: sleepy.rb, line: 1
Returning After: 21304 nanoseconds
...
```

Running our modified DTrace script, we see that this time around we are only triggering our probes when entering into and returning from the `even` and `odd` methods. Now that we have learned a fair few DTrace basics, we can now move on to the more advanced topic of writing a DTrace script that will allow us to measure mutex contention in Ruby programs.

### Monitoring mutex contention with DTrace

The goal of this section is to come up with a DTrace script that measures mutex contention in a multi-threaded Ruby program. This is far from a trivial undertaking and will require us to go and investigate the source code of the Ruby language itself. However, before we get to that, let's first take a look at the Ruby program that we will analyze with the DTrace script that we are going to write in this section.

```ruby
# mutex.rb
mutex = Mutex.new
threads = []

threads << Thread.new do
  loop do
    mutex.synchronize do
      sleep 2
    end
  end
end

threads << Thread.new do
  loop do
    mutex.synchronize do
      sleep 4
    end
  end
end

threads.each(&:join)
```

The above Ruby code starts by creating a mutex object, after which it kicks off two threads. Each thread runs an infinite loop that causes the thread to grab the mutex for a short while before releasing it again. Since the second thread is holding onto the mutex for longer than the first thread, it is intuitively obvious that the first thread will spend a fair amount of time waiting for the second thread to release the mutex.

Our goal is to write a DTrace script that tracks when a given thread has to wait for a mutex to become available, as well as which particular thread is holding the mutex at that point in time. To the best of my knowledge, it is impossible to obtain this contention information by monkey patching the Mutex object, which makes this a great showcase for DTrace. Please get in touch if you think I am wrong on this.

In order for us to write a DTrace script that does the above, we first need to figure out what happens when a thread calls `synchronize` on a Mutex object. However, mutexes and their methods are implemented as part of the Ruby language itself. This means we are going to have to go and take a look at the [Ruby MRI source code](https://github.com/ruby/ruby/tree/ruby_2_2) itself, which is written in C. Do not worry if you've never used C. We'll focus on only those parts relevant to our use case.

Let's start at the beginning and look closely at what happens when you call `synchronize` on a Mutex object. We'll take this step by step:

1. `synchronize` ([source](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L1254)) calls `rb_mutex_synchronize_m`
2. `rb_mutex_synchronize_m` ([source](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L502)) checks if `synchronize` was called with a block and then goes on to call `rb_mutex_synchronize`
3. `rb_mutex_synchronize` ([source](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L488)) calls `rb_mutex_lock`
4. `rb_mutex_lock` ([source](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L241)) is where the currently active Ruby thread that executed the `mutex.synchronize` code will try to grab the mutex


There's a lot going on in `rb_mutex_lock`. The one thing that we are especially interested in is the call to `rb_mutex_trylock` ([source](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L157)) on [line 252](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L252). This method immediately returns `true` or `false` depending on whether the Ruby thread managed to grab the mutex. By following the code from line 252 onwards, we can see that `rb_mutex_trylock` returning `true` causes `rb_mutex_lock` to immediately return. On the other hand, `rb_mutex_lock` returning `false` causes `rb_mutex_lock` to keep executing (and occasionally blocking) until the Ruby thread has managed to get a hold of the mutex.

This is actually all we needed to know in order to be able to go and write our DTrace script. Our investigation showed that when a thread starts executing `rb_mutex_lock`, this means it wants to acquire a mutex. And when a thread returns from `rb_mutex_lock`, we know that it managed to successfully obtain this lock. In a previous section, we saw how DTrace allows us to set probes that fire upon entering into and returning from particular methods. We can now go ahead and use this to write our DTrace script.

Let's go over what exactly our DTrace script should do.

1. when our Ruby program calls `mutex.synchronize`, we want to make a note of which particular file and line these instructions appear on. We will see later how this allows us to pinpoint problematic code.
2. when `rb_mutex_lock` starts executing, we want to write down the current timestamp, as this is when the thread starts trying to acquire the mutex.
3. when `rb_mutex_lock` returns, we want to compare the current timestamp with the one we wrote down earlier, as this tells us how long the thread had to wait trying to acquire the mutex. We then want to print this duration, along with some information about the location of this particular `mutex.synchronize` call in the code base, to the terminal.

Putting this all together, we end up with a DTrace script like shown below.

```C
/* mutex.d */
ruby$target:::cmethod-entry
/copyinstr(arg0) == "Mutex" && copyinstr(arg1) == "synchronize"/
{
  self->file = copyinstr(arg2);
  self->line = arg3;
}

pid$target:ruby:rb_mutex_lock:entry
/self->file != NULL && self->line != NULL/
{
  self->mutex_wait_start = timestamp;
}

pid$target:ruby:rb_mutex_lock:return
/self->file != NULL && self->line != NULL/
{
  mutex_wait_ms = (timestamp - self->mutex_wait_start) / 1000;
  printf("Thread %d acquires mutex %d after %d ms - %s:%d\n", tid, arg1, mutex_wait_ms, self->file, self->line);
  self->file = NULL;
  self->line = NULL;
}
```

The snippet above contains three different probes, the first of which is a Ruby probe that fires whenever a C method is entered. Since the Mutex class and its methods have been implemented in C as [part of the Ruby MRI](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L1246-L1255), it makes sense for us to use a `cmethod-entry` probe. Note how we use a predicate to ensure this probe only gets triggered when its first two arguments are "Mutex" and "synchronize". We covered earlier how these arguments [correspond to the class and method name](https://ruby-doc.org/core-2.1.0/doc/dtrace_probes_rdoc.html) of the Ruby code that triggered the probe. So this predicate guarantees that this particular probe will only fire when our Ruby code calls the `synchronize` method on a Mutex object.

The rest of this probe is rather straightforward. The only thing we are doing is storing the file and line number of the Ruby code that triggered the probe into thread-local variables. We are using thread-local variables for two reasons. Firstly, thread-local variables make it trivial to share data with other probes. Secondly, Ruby programs that make use of mutexes will generally be running multiple threads. Using thread-local variables ensures that each Ruby thread will get its own set of probe-specific variables.

Our second probe comes from the pid provider. This provider supplies us with probes for every internal method of a process. In this case we want to use it to get notified whenever `rb_mutex_lock` starts executing. We saw earlier that a thread will invoke this method when starting to acquire a mutex. The probe itself is pretty simple in that it just stores the current time in a thread-local variable, so as to keep track of when a thread started trying to obtain a mutex. We also use a simple predicate that ensures this probe can only be triggered after the previous probe has fired.

The final probe fires whenever `rb_mutex_lock` finishes executing. It has a similar predicate as the second probe so as to ensure it can only be triggered after the first probe has fired. We saw earlier how `rb_mutex_lock` returns whenever a thread has successfully obtained a lock. We can easily calculate the time spent waiting on this lock by comparing the current time with the previously stored `self->mutex_wait_start` variable. We then print the time spent waiting, along with the IDs of the current thread and mutex, as well as the location of where the call to `mutex.synchronize` took place. We finish this probe by assigning `NULL` to the `self->file` and `self->line` variables, so as to ensure that the second and third probe can only be triggered after the first one has fired again.

In case you are wondering about how exactly the thread and mutex IDs are obtained, `tid` is a built-in DTrace variable that identifies the current thread. A `pid:::return` probe stores the return value of the method that triggered it inside its `arg1` variable. The `rb_mutex_lock` method just happens to [return an identifier for the mutex that was passed to it](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L306), so the `arg1` variable of this probe does in fact contain the mutex ID.

The final result looks a lot like this.

```bash
$ sudo dtrace -q -s mutex.d -c 'ruby mutex.rb'

Thread 286592 acquires mutex 4313316240 after 2 ms - mutex.rb:14
Thread 286591 acquires mutex 4313316240 after 4004183 ms - mutex.rb:6
Thread 286592 acquires mutex 4313316240 after 2004170 ms - mutex.rb:14
Thread 286592 acquires mutex 4313316240 after 6 ms - mutex.rb:14
Thread 286592 acquires mutex 4313316240 after 4 ms - mutex.rb:14
Thread 286592 acquires mutex 4313316240 after 4 ms - mutex.rb:14
Thread 286591 acquires mutex 4313316240 after 16012158 ms - mutex.rb:6
Thread 286592 acquires mutex 4313316240 after 2002593 ms - mutex.rb:14
Thread 286591 acquires mutex 4313316240 after 4001983 ms - mutex.rb:6
Thread 286592 acquires mutex 4313316240 after 2004418 ms - mutex.rb:14
Thread 286591 acquires mutex 4313316240 after 4000407 ms - mutex.rb:6
Thread 286592 acquires mutex 4313316240 after 2004163 ms - mutex.rb:14
Thread 286591 acquires mutex 4313316240 after 4003191 ms - mutex.rb:6
Thread 286591 acquires mutex 4313316240 after 2 ms - mutex.rb:6
Thread 286592 acquires mutex 4313316240 after 4005587 ms - mutex.rb:14
...
```

We can get some interesting info about our program just by looking at the above output.

1. there are two threads: 286591 and 286592
2. both threads try to acquire mutex 4313316240
3. the mutex acquisition code of the fist thread lives a line 6 of the mutex.rb file
4. the acquisition code of the second thread is located at line 14 of the same file
5. there is a lot of mutex contention, with threads having to wait several seconds for the mutex to become available

Of course we already knew all of the above was going to happen, as we were familiar with the source code of our Ruby program. The real power of DTrace lies in how we can now go and run our mutex.d script against any Ruby program, no matter how complex, and obtain this level of information without having to read any source code at all. We can even go one step further and run our mutex contention script against an already running Ruby process with `sudo dtrace -q -s mutex.d -p <pid>`. This can even be run against active production code with minimal overhead.

Before moving on to the next section, I'd just like to point out that the above DTrace output actually tells us some cool stuff about how the Ruby MRI schedules threads. If you look at lines 3-6 of the output, you'll notice that the second thread got scheduled four times in a row. This tells us that when multiple threads are competing for a mutex, the Ruby MRI does not care if a particular thread recently held the mutex.

### Advanced mutex contention monitoring

We can take the above DTrace script one step further by adding an additional probe that triggers whenever a thread releases a mutex. We will also be slightly altering the output of our script so as to print timestamps rather than durations. While this will make the script's output less suitable for direct human consumption, this timestamp information will make it easier to construct a chronological sequence of the goings-on of our mutexes.

Note that the above doesn't mean that we no longer care about producing output suitable for humans. We'll see how we can easily write a Ruby script to aggregate this new output into something a bit more comprehensive. As an aside, DTrace actually has built-in logic for aggregating data, but I personally prefer to focus my DTrace usage on obtaining data that would otherwise be hard to get, while having my aggregation logic live somewhere else.

Let's start by having a look at how to add a probe that can detect a mutex being released. Luckily, this turns out to be relatively straightforward. It turns out there is a C method called `rb_mutex_unlock` ([source](https://github.com/ruby/ruby/blob/325587ee7f76cbcabbc1e6d181cfacb976c39b52/thread_sync.c#L371)) that releases mutexes. Similarly to `rb_mutex_lock`, this method returns an identifier to the mutex it acted on. So all we need to do is add a probe that fires whenever `rb_mutex_unlock` returns. Our final script looks like this.

```C
/* mutex.d */
ruby$target:::cmethod-entry
/copyinstr(arg0) == "Mutex" && copyinstr(arg1) == "synchronize"/
{
  self->file = copyinstr(arg2);
  self->line = arg3;
}

pid$target:ruby:rb_mutex_lock:entry
/self->file != NULL && self->line != NULL/
{
  printf("Thread %d wants to acquire mutex %d at %d - %s:%d\n", tid, arg1, timestamp, self->file, self->line);
}

pid$target:ruby:rb_mutex_lock:return
/self->file != NULL && self->line != NULL/
{
  printf("Thread %d has acquired mutex %d at %d - %s:%d\n", tid, arg1, timestamp, self->file, self->line);
  self->file = NULL;
  self->line = NULL;
}

pid$target:ruby:rb_mutex_unlock:return
{
  printf("Thread %d has released mutex %d at %d\n", tid, arg1, timestamp);
}
```

```bash
$ sudo dtrace -q -s mutex.d -c 'ruby mutex.rb'

Thread 500152 wants to acquire mutex 4330240800 at 53341356615492 - mutex.rb:6
Thread 500152 has acquired mutex 4330240800 at 53341356625449 - mutex.rb:6
Thread 500153 wants to acquire mutex 4330240800 at 53341356937292 - mutex.rb:14
Thread 500152 has released mutex 4330240800 at 53343360214311
Thread 500152 wants to acquire mutex 4330240800 at 53343360266121 - mutex.rb:6
Thread 500153 has acquired mutex 4330240800 at 53343360301928 - mutex.rb:14
Thread 500153 has released mutex 4330240800 at 53347365475537
Thread 500153 wants to acquire mutex 4330240800 at 53347365545277 - mutex.rb:14
Thread 500152 has acquired mutex 4330240800 at 53347365661847 - mutex.rb:6
Thread 500152 has released mutex 4330240800 at 53349370397555
Thread 500152 wants to acquire mutex 4330240800 at 53349370426972 - mutex.rb:6
Thread 500153 has acquired mutex 4330240800 at 53349370453489 - mutex.rb:14
Thread 500153 has released mutex 4330240800 at 53353374785751
Thread 500153 wants to acquire mutex 4330240800 at 53353374834184 - mutex.rb:14
Thread 500152 has acquired mutex 4330240800 at 53353374868435 - mutex.rb:6
...
```

The above output is pretty hard to parse for a human reader. The snippet below shows a Ruby program that aggregates this data into a more readable format. I'm not going to go into the details of this Ruby program as it is essentially just a fair bit of string filtering with some bookkeeping to help keep track of how each thread interacts with the mutexes and the contention this causes.

```ruby
# aggregate.rb
mutex_owners     = Hash.new
mutex_queuers    = Hash.new {|h,k| h[k] = Array.new }
mutex_contention = Hash.new {|h,k| h[k] = Hash.new(0) }

time_of_last_update = Time.now
update_interval_sec = 1

ARGF.each do |line|
  # when a thread wants to acquire a mutex
  if matches = line.match(/^Thread (\d+) wants to acquire mutex (\d+) at (\d+) - (.+)$/)
    captures  = matches.captures
    thread_id = captures[0]
    mutex_id  = captures[1]
    timestamp = captures[2].to_i
    location  = captures[3]

    mutex_queuers[mutex_id] << {
      thread_id: thread_id,
      location:  location,
      timestamp: timestamp
    }
  end

  # when a thread has acquired a mutex
  if matches = line.match(/^Thread (\d+) has acquired mutex (\d+) at (\d+) - (.+)$/)
    captures  = matches.captures
    thread_id = captures[0]
    mutex_id  = captures[1]
    timestamp = captures[2].to_i
    location  = captures[3]

    # set new owner
    mutex_owners[mutex_id] = {
      thread_id: thread_id,
      location: location
    }

    # remove new owner from list of queuers
    mutex_queuers[mutex_id].delete_if do |queuer|
      queuer[:thread_id] == thread_id &&
      queuer[:location] == location
    end
  end

  # when a thread has released a mutex
  if matches = line.match(/^Thread (\d+) has released mutex (\d+) at (\d+)$/)
    captures  = matches.captures
    thread_id = captures[0]
    mutex_id  = captures[1]
    timestamp = captures[2].to_i

    owner_location = mutex_owners[mutex_id][:location]

    # calculate how long the owner caused each queuer to wait
    # and change queuer timestamp to the current timestamp in preparation
    # for the next round of queueing
    mutex_queuers[mutex_id].each do |queuer|
      mutex_contention[owner_location][queuer[:location]] += (timestamp - queuer[:timestamp])
      queuer[:timestamp] = timestamp
    end
  end

  # print mutex contention information
  if Time.now - time_of_last_update > update_interval_sec
    system('clear')
    time_of_last_update = Time.now

    puts 'Mutex Contention'
    puts "================\n\n"

    mutex_contention.each do |owner_location, contention|
      puts owner_location
      owner_location.length.times { print '-' }
      puts "\n"

      total_duration_sec = 0.0
      contention.sort.each do |queuer_location, queueing_duration|
        duration_sec = queueing_duration / 1000000000.0
        total_duration_sec += duration_sec
        puts "#{queuer_location}\t#{duration_sec}s"
      end
      puts "total\t\t#{total_duration_sec}s\n\n"
    end
  end
end
```

```bash
$ sudo dtrace -q -s mutex.d -c 'ruby mutex.rb' | ruby aggregate.rb


Mutex Contention
================

mutex.rb:6
----------
mutex.rb:14	  10.016301065s
total		  10.016301065s

mutex.rb:14
-----------
mutex.rb:6	  16.019252339s
total		  16.019252339s
```

The final result looks like shown above. Note that our program will clear the terminal every second before printing summarized contention information. Here we see that after running the program for a bit, `mutex.rb:6` caused `mutex.rb:14` to spend about 10 seconds waiting for the mutex to become available. The `total` field indicates the total amount of waiting across all other threads caused by `mutex.rb:6`. This number becomes more useful when there are more than two threads competing for a single mutex.

I want to stress that while the mutex.rb shown here was kept simple on purpose, our code is in fact more than capable of handling more complex scenarios. For example, let's have a look at some Ruby code that uses multiple mutexes, some of which are nested.

```ruby
# mutex.rb
mutexes =[Mutex.new, Mutex.new]
threads = []

threads << Thread.new do
  loop do
    mutexes[0].synchronize do
      sleep 2
    end
  end
end

threads << Thread.new do
  loop do
    mutexes[1].synchronize do
      sleep 2
    end
  end
end

threads << Thread.new do
  loop do
    mutexes[1].synchronize do
      sleep 1
    end
  end
end

threads << Thread.new do
  loop do
    mutexes[0].synchronize do
      sleep 1
      mutexes[1].synchronize do
        sleep 1
      end
    end
  end
end

threads.each(&:join)
```

```bash
$ sudo dtrace -q -s mutex.d -c 'ruby mutex.rb' | ruby aggregate.rb


Mutex Contention
================

mutex.rb:6
----------
mutex.rb:30	  36.0513079s
total		  36.0513079s

mutex.rb:14
-----------
mutex.rb:22	  78.123187353s
mutex.rb:32	  36.062005125s
total		  114.185192478s

mutex.rb:22
-----------
mutex.rb:14	  38.127435904s
mutex.rb:32	  19.060814411s
total		  57.188250315000005s

mutex.rb:32
-----------
mutex.rb:14	  24.073966949s
mutex.rb:22	  24.073383955s
total		  48.147350904s

mutex.rb:30
-----------
mutex.rb:6	  103.274153073s
total		  103.274153073s
```

The above output tells us very clearly that we should concentrate our efforts on lines 14 and 30 when we want to try to make our program faster. The really cool thing about all this is that this approach will work regardless of the complexity of your program and requires absolutely no familiarity with the source code at all. You can literally run this against code you've never seen and walk away with a decent idea of where the mutex bottlenecks are located. And on top of that, since we are using DTrace, we don't even have to add any instrumentation code to the program we want to investigate. We can just run this against an already active process without even having to interrupt it.

### Conclusion

I hope to have convinced you that DTrace is a pretty amazing tool that can open up whole new ways of trying to approach a problem. There is so so much I haven't even touched on yet. The topic is just too big to cover in a single post. If you're interested in learning DTrace, here are some resources I can recommend:

- [The DTrace Toolkit](https://github.com/opendtrace/toolkit) is a curated collection of DTrace script for various systems
- I often find myself peeking at the [DTrace QuickStart](http://www.tablespace.net/quicksheet/dtrace-quickstart.html) and [The DTrace Cheatsheet](http://www.brendangregg.com/DTrace/DTrace-cheatsheet.pdf) when I can't quite remember how something works
- [DTrace: Dynamic Tracing in Oracle Solaris, Mac OS X and FreeBSD](https://www.amazon.com/DTrace-Dynamic-Tracing-Solaris-FreeBSD/dp/0132091518)
The first chapters of this book act as a DTrace tutorial. The rest of the book is all about how to use DTrace to solve real-life scenarios with tons and tons of examples.

Just one more thing before I finish this. If you're on OS X and encounter DTrace complaining about not being able to control executables signed with restricted entitlements, be aware that you can easily work around this by using the `-p` parameter to directly specify the pid of the process you want DTrace to run against. Please contact me if you manage to find the proper fix for this.

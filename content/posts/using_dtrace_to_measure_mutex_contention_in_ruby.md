+++
date = "2016-09-24T21:24:12+00:00"
title = "Using DTrace to measure mutex contention in Ruby"
type = "post"
ogtype = "article"
topics = [ "ruby", "dtrace" ]
+++

I recently found myself working on Ruby code containing a sizable number of threads and mutexes. It wasn't before long that I started wishing for some tool that could tell me which particular mutexes were the most heavily contended. After all, this type of information can be worth its weight in gold when trying to diagnose why your threaded program is running slower than expected.

This is where [DTrace](http://dtrace.org/guide/preface.html) enters the picture. DTrace is a tracing framework that enables you to instrument application and system internals, thereby allowing you to measure and collect previously inaccessible metrics. Personally, I think of DTrace as black magic that allows me to gather a ridiculous amount of information about what is happening on my computer. We will see later just how fine-grained this information can get.

DTrace is available on Solaris, OS X, and FreeBSD. There is some Linux support as well, but you might be better off using one of the Linux specific alternatives instead. One of DTrace's authors has published some [helpful](http://www.brendangregg.com/dtrace.html) [articles](http://www.brendangregg.com/blog/2015-07-08/choosing-a-linux-tracer.html) about this. Please note that all the work for this particular article was done on a MacBook running OS X El Capitan (version 10.11).

### Enabling DTrace for Ruby on OS X

El Capitan comes with a new security feature called [System Integrity Protection](https://en.wikipedia.org/wiki/System_Integrity_Protection) that helps prevent malicious software from tampering with your system. Regrettably, it also prevents DTrace from working. We will need to disable SIP by following [these instructions](http://stackoverflow.com/a/33584192/1420382). Note that it is possible to only partially disable SIP, although doing so will still leave DTrace unable to attach to restricted processes. Personally, I've completely disabled SIP on my machine.

Next, we want to get DTrace working with Ruby. Although Ruby has DTrace support, there is a very good chance that your currently installed Ruby binary does not have this support enabled. This is especially likely to be true if you compiled your Ruby binary locally on an OS X system, as OS X does not allow the Ruby compilation process to access the system DTrace binary, thereby causing the resulting Ruby binary to lack DTrace functionality. More information about this can be found [here](http://stackoverflow.com/a/29232051/1420382).

I've found the easiest way to get a DTrace compatible Ruby on my system was to just go and download a precompiled Ruby binary. Naturally we want to be a bit careful about this, as downloading random binaries from the internet is not the safest thing. Luckily, the good people over at [rvm.io](https://rvm.io/) host DTrace compatible Ruby binaries that we can safely download.

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

The first line of our script tells DTrace which probes we want to use. In this particular case we are using `syscall:*:*:entry` to match every single probe associated with initiating a system call. DTrace has individual probes for every possible system call, so if DTrace were to have no built-in functionality for matching multiple probes, I would have been forced to manually specify every single system call probe myself, and our script would have been a whole lot longer.

I want to briefly cover some DTrace terminology before continuing on. Every DTrace probe adheres to the `<provider>:<module>:<function>:<name>` description format. In the script above we asked DTrace to match all probes of the `syscall` provider that have `entry` as their name. In this particular example we explicitly used the `*` character to show that we want to match multiple probes. However, keep in mind that the use of the `*` character is optional. Most DTrace documentation would opt for `syscall:::entry` instead.

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

DTrace probes have been present in Ruby [since Ruby 2.0](https://tenderlovemaking.com/2011/12/05/profiling-rails-startup-with-dtrace.html) came out.
A list of Ruby probes can be found [here](http://ruby-doc.org/core-2.2.3/doc/dtrace_probes_rdoc.html).
An interesting thing to note is that DTrace probes come in two flavors: dynamic and static probes. Dynamic
probes are only found in the `pid` and `fbt` probe providers. This means that the vast majority of
available probes (including Ruby probes) is static.

So what exactly is the difference between static and dynamic probes? In order to explain that
we first need to take a look at how DTrace works. When you invoke DTrace on a process you are
effectively giving DTrace permission to patch live instructions in the address space of this
process with additional DTrace instrumentation. Remember how we had to disable the System Integrity
Protection check in order to get DTrace to work on El Capitan? This is why.

In the case of dynamic probes, DTrace instrumentation only gets added to a process when
DTrace is invoked on this process. In other words, dynamic probes cause literally
*zero* overhead when not enabled. On the other hand, static probes have to be compiled
into the binary that wants to make use of them. A good example of this is [Ruby's
probes.d file](https://github.com/ruby/ruby/blob/trunk/probes.d). However, when a process
with static probes does not have DTrace invoked on it, any probe instructions are converted
into NOP operations. This usually introduces a negligible, but *non-zero*, performance impact.
More information about DTrace overhead can be found here, here, and here.
http://dtrace.org/blogs/brendan/2011/02/18/dtrace-pid-provider-overhead/
http://www.solarisinternals.com/wiki/index.php/DTrace_Topics_Overhead#Dynamic_Probes - dynamic ovhd
http://www.solarisinternals.com/wiki/index.php/DTrace_Topics_Overhead#Static_Probes - dtrace nop

Let's start by listing which DTrace probes are available for a Ruby process. We saw earlier
that Ruby comes with static probes baked in. We can ask DTrace to list these probes for us
with the following command.

$ sudo dtrace -l -m ruby -c 'ruby -v'

ID   PROVIDER            MODULE                          FUNCTION NAME
114188  ruby86029              ruby                   empty_ary_alloc array-create
114189  ruby86029              ruby                           ary_new array-create
114190  ruby86029              ruby                     vm_call_cfunc cmethod-entry
114191  ruby86029              ruby                     vm_call0_body cmethod-entry
114192  ruby86029              ruby                      vm_exec_core cmethod-entry
114193  ruby86029              ruby                     vm_call_cfunc cmethod-return
114194  ruby86029              ruby                     vm_call0_body cmethod-return
114195  ruby86029              ruby                        rb_iterate cmethod-return
114196  ruby86029              ruby                      vm_exec_core cmethod-return
114197  ruby86029              ruby                   rb_require_safe find-require-entry
114198  ruby86029              ruby                   rb_require_safe find-require-return
114199  ruby86029              ruby                          gc_marks gc-mark-begin
...

Let's take a moment to look at the command we entered here. We saw earlier that we
can use `-l` to have DTrace list its probes. Now we are also using `-m ruby` to
tell DTrace to limit its listing to probes from the ruby module. However, DTrace
will only list its Ruby probes if you specifically tell it you are interested in
invoking DTrace on a Ruby process. This is what `-c 'ruby -v'` is for. The `-c`
parameter allows us to specify a command that creates a process we want to run
DTrace against. Here we are using `ruby -v` to spawn a small Ruby process.

But wait, there's more! The `sudo dtrace -l` command will not list any probes from
the pid provider. This is because the pid provider is a special provider that
actually defines a [class of providers](http://dtrace.org/guide/chp-pid.html). The
snippet below shows the easiest way to get the Ruby specific pid provider probes
listed.

$ sudo dtrace -l -n 'pid$target:::entry' -c 'ruby -v' | grep 'ruby'

ID   PROVIDER            MODULE                          FUNCTION NAME
1395302   pid86272              ruby                             start entry
1395303   pid86272              ruby                              main entry
1395304   pid86272              ruby                          Init_ext entry
1395305   pid86272              ruby            X509_STORE_set_ex_data entry
1395306   pid86272              ruby            X509_STORE_get_ex_data entry
1395307   pid86272              ruby                        string2hex entry
1395308   pid86272              ruby                 ossl_x509_ary2sk0 entry
1395309   pid86272              ruby                        ossl_raise entry
1395310   pid86272              ruby          ossl_protect_x509_ary2sk entry
1395311   pid86272              ruby                  ossl_x509_ary2sk entry
1395312   pid86272              ruby                  ossl_x509_sk2ary entry
1395313   pid86272              ruby               ossl_x509crl_sk2ary entry
...

Every pid entry probe has a corresponding pid return probe. These probes are great
as they give us insight into which internal functions are getting called, the arguments
passed to these, as well as their return values, and even the offset in the function
of the return instruction (useful for when a function has multiple return instructions). More
information about the pid provider can be found [here](http://dtrace.org/blogs/brendan/2011/02/09/dtrace-pid-provider).


A first DTrace script for Ruby

Let's have a look at a simple DTrace script for Ruby. Our script will tell us when a
method starts and stops executing, along with the methods execution time. The Ruby program
below will be our starting point.

# sleepy.rb

def even(rnd)
  sleep rnd
end

def odd(rnd)
  sleep rnd
end

loop do
  rnd = rand(4)
  (rnd % 2 == 0) ? even(rnd) : odd(rnd)
end


This Ruby program is clearly not going to win any awards. It is just one endless loop, each
iteration of which calls a method depending on whether a random number was even or odd. While
this is clearly a very contrived example, we can nevertheless make great use of it to illustrate
the power of DTrace.

# sleepy.d
ruby$target:::method-entry
{
  self->start = timestamp;
  printf("Entering Method: class: %s, method: %s, file: %s, line: %d\n", copyinstr(arg0), copyinstr(arg1), copyinstr(arg2), arg3);
}

ruby$target:::method-return
{
  printf("Returning After: %d nanoseconds\n", (timestamp - self->start));
}

The above snippet introduces quite a few new concepts. Let's start by having a look at the
`arg0`, `arg1`, ... variables. These are actually just the arguments that Ruby passes to the
method-entry probe. If we want to know what these arguments represent, all we have to do is
look at [the documentation for this particular probe](http://ruby-doc.org/core-2.2.3/doc/dtrace_probes_rdoc.html#label-Declared+probes).

*ruby:::method-entry(classname, methodname, filename, lineno);*

classname: name of the class (a string)
methodname: name of the method about to be executed (a string)
filename: the file name where the method is _being called_ (a string)
lineno: the line number where the method is _being called_ (an int)

This tells us that `arg0` represents the class name, `arg1` represents the method name, ...
Equally important is that the documentation tells us that the first three argumets are strings, while
the fourth one is an integer. We need this information when we want to use `printf` to print these
values.

You probably noticed that we are wrapping string variables inside the built-in `copyinstr` method.
The reason for this is a bit complex. When strings are passed as an arugment to a DTrace probe, we don't
actually pass the entire string. We just pass the memory address where the string starts. This memory
address points to a string that is stored in user space. However, DTrace probes are executed in the kernel,
so in order for the probe to read the string, we need to copy this user process data into the kernel's address space.
The `copyinstr` is a built-in DTrace function that takes care of this for us.

The `self->start` notation is interesting as well. DTrace variables that start with `self->` are thread-local variables
that can be read from and written to across probes. Each thread of the process that you are calling DTrace on gets its
own thread-local variables. There is no way for these variables to interact across threads. Since our Ruby program is
single-threaded, we are just using thread-local variables to share the `self->start` variable across the `method-entry`
and `method-return` probes.

Let's go ahead and run this DTrace script on our Ruby program.

sudo dtrace -q -s sleepy.d -c 'ruby sleepy.rb'

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

It's a bit hard to convey in the snippet above, but our DTrace program is generating well over a 1000 lines of output.
These lines can be divided into two sections: a very large section that lists all the Ruby methods being called as part
of the program getting ready to run, and a much smaller section that lists whether our program is calling the `odd` or
`even` functions, along with the time spent in each of these function calls.

While the above output gives us great detail about what our Ruby program is doing, we really only want to gather
information about the `odd` and `even` methods being called. DTrace supports predicates to make just these kind
of things possible. Predicates are `/` wrapped conditions that define whether the code of a particular probe
should be executed. Shown below is how we can use predicates to limit our output to just the `odd` and `even`
methods.



The abvoe snippet does not quite capture it, but
Our DTrace program is generating





mention the code that gets executed as part of Ruby startup. Use this as way to
introduce predicates to narrow which information gets shown.

- point out that we can use -p to specify pid directly. This allows us to attach to running Ruby processes
on productio nmachines










- example of using DTrace with Ruby
- using -c vs DTracing an already running process


sudo dtrace -ln 'pid$target:::entry' -c 'ruby foo.rb' | grep 'utex' | grep ruby
VS
sudo dtrace -n 'ruby$target:::cmethod-entry { printf("%s", copyinstr(arg0)); }' -c "ruby foo.rb"
-ttp://dtrace.org/blogs/brendan/2011/02/18/dtrace-pid-provider-overhead/
- fine-grained information enables the creation absolutely amazing tools.





Ruby mutex contention and DTrace



Additional resources


Ruby and DTrace

There are an incredibly amount of probes available

Now to actually run this stuff. The dtrace command needs to be run as root - with superuser privileges. Ordinarily you’d use sudo to run a command as root, but some DTrace behaviors don’t work reliably when run with sudo, so you can start a root shell with sudo -i, or give it a shell, like with sudo bash.
Use # at the start of commands to indicate a sudo bash session.

describes a function, or a set of functions, to  Probes allow you to hook Probes are small functions that we can hook  fired when a given condition is met.
Such a condition could be a certain process making a specific system call, or a runtime returning from
a given method.


fine-grained
https://github.com/opendtrace/toolkit <- how to run. Add example code to run against
give examples - comment on syntax

sudo dtrace -ln 'pid$target:::entry' -c 'ruby foo.rb' | grep 'utex' | grep ruby
VS
sudo dtrace -n 'ruby$target:::cmethod-entry { printf("%s", copyinstr(arg0)); }' -c "ruby foo.rb"

- http://www.tablespace.net/quicksheet/dtrace-quickstart.html
- probes
https://github.com/opendtrace/toolkit <- how to run. Add example code to run against

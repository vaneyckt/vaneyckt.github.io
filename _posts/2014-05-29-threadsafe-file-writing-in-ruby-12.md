---
layout: post
title: "Threadsafe file writing in Ruby (1/2)"
category: ruby
---
{% include JB/setup %}

I found myself wondering about safe ways for multiple threads to write to a given file in Ruby and ended up finding a great post on [Threadsafe File Consistency in Ruby](http://blog.douglasfshearer.com/post/17547062422/threadsafe-file-consistency-in-ruby). It's an absolutely brilliant write-up by someone who has clearly invested a lot of time in this:

[Atomic writes](http://apidock.com/rails/File/atomic_write/class) ensure that a process (or thread) that reads from a file will never see a half-written file no matter how frequent the file is being written to. The approach take here is to redirect any writes into a temporary file; once the write has finished the original file is replaced with the temporary one by making a `mv` system call. Since the `mv` system call is [guaranteed to be atomic](http://www.linuxmisc.com/9-unix-programmer/457187f6a27d0540.htm) within [file boundaries](http://superuser.com/questions/586540/where-does-boundary-of-file-system-lie-in-linux), the replacement of the file will appear to be instantaneous to any reading processes.

Note that the above approach only guarantees that no half-written files will be read from. It does not make any guarantees about what happens when multiple processes try to write to a file at the same time. The problem in this case is two-fold. In order to write to a file a process first needs to locate where in the file to write to. This is done using the `lseek` system call. The actual writing is then done by a separate `write` system call.

The first problem is that multiple processes writing to a single file can interleave their calls like so:

- process A performs `lseek`
- process B performs `lseek`
- process A calls `write`
- process B calls `write` and ends up overwriting the changes made by process A

The second problem is that while `lseek` and `write` are both atomic, there is [no guarantee](http://stackoverflow.com/questions/14387104/atomic-writes-in-linux) that all the changes made by a single process will be performed in a single `write` call. Instead multiple processes writing to a single file could have their `write` calls interleaved, causing the new contents of the file to be out of order.

The solution here is to use a [file lock](http://unix.stackexchange.com/questions/107038/obtain-exclusive-read-write-lock-on-a-file-for-atomic-updates). There is some great Ruby code for this on the site I linked at the top of this post, as well as some examples in the [docs](http://www.ruby-doc.org/core-2.1.1/File.html#method-i-flock), and of course some [great posts on StackOverflow](http://stackoverflow.com/a/15304835/1420382).

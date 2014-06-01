---
layout: post
title: "Threadsafe file writing in Ruby (2/2)"
category: ruby
---
{% include JB/setup %}

In a previous post on this topic we went over the importance of using file locks when having multiple concurrent processes writing to the same file. However, using a file lock can cause a certain amount of contention between processes. This is why you'll sometimes see [lock-free logging implementations](http://www.jstorimer.com/blogs/workingwithcode/7982047-is-lock-free-logging-safe).

**Lock-free Logging**

Lock-free logging is all about the use of the `O_APPEND` flag. By opening a file with this flag you are effectively telling the OS to force each `write` call to this file to append its data to the end of the file. Unlike the scenario in our previous post where `lseek` and `write` calls of different processes could end up interleaved, the `O_APPEND` flag guarantees that ["the file offset shall be set to the end of the file prior to each write and no intervening file modification operation shall occur between changing the file offset and the write operation"](http://pubs.opengroup.org/onlinepubs/009695399/functions/pwrite.html). This guarantee causes lots of people to think that having multiple processes writing to the same file opened with the `O_APPEND` flag is safe to do. Unfortunately this is [not correct](https://github.com/steveklabnik/mono_logger/issues/2).

The problem boils down to an issue raised in the previous post on this topic: the [lack of any guarantee](http://stackoverflow.com/questions/14387104/atomic-writes-in-linux) that all changes made by a single process will be performed in a single `write` call. Since `write` calls are [not atomic](http://stackoverflow.com/questions/7236475/what-happens-if-a-write-system-call-is-called-on-same-file-by-2-different-proces), any data written with this `O_APPEND` approach can still be reordered due to interleaved `write` operations. As an aside, do note that using `O_APPEND` will prevent multiple processes from overwriting each other's data.

So when is it safe to use this `O_APPEND` approach? In theory it should never be used; however in practice it will work correctly the vast majority of the time. [Jesse Storimer](http://www.jstorimer.com/) asked around why this is, and got [some answers](http://librelist.com/browser//usp.ruby/2013/6/5/o-append-atomicity/#c794fe8b22b5e09de4c38e6994b4e201). It turns out most file systems don't like to interrupt `write` operations that only want to add a small amount of data, e.g. a line in a log file. This means that the majority of such `write` calls can be treated as atomic for most of the time even though it is not safe to do so. This behavior also explains the large amount of confusing information on the internet regarding this topic.

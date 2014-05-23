---
layout: post
title: "Synchronization and volatile variables"
category: java
---
{% include JB/setup %}

Safely sharing a variable between threads can be done by either using the standard synchronization mechanism or by declaring the variable to be `volatile`. While both approaches will prevent any reordering issues from occurring, there are a few things to keep in mind when opting for the latter choice:

- volatile variables are never cached, so a read will always return the most recent write.
- accessing volatile variables is done without any locking. This means that only simple reads and writes are guaranteed to be atomic operations. More complex read-modify-write operations (like the `increment` method in the code above) can not be performed atomically on volatile variables.
- since accessing volatile variables does not use a lock, a thread B will never have to wait for a thread A to finish before being allowed access to the volatile variable. This fast access makes them very suited for use as status flags in high-performance multithreaded applications.

{% gist vaneyckt/8386d8194936ab722f6d %}

In essence a `volatile int` is not unlike the `SynchronizedInteger` class shown above, but without the `increment` method or the need to obtain a lock before being allowed to perform `get` or `set`.

---
layout: post
title: "The java.util.concurrent.atomic package"
category: java
---
{% include JB/setup %}

A super useful [java package](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic
/package-summary.html) for when you find yourself writing multithreaded code. It contains a set of atomic variable classes for effecting atomic state transitions on numbers and object references.

Let's say you have a need for atomic transactions on an integer counter. You could either create a class with synchronized methods for modifying an integer counter field, or alternatively you could just use `AtomicInteger`.

Some of the more straightforward classes in this package:

- [AtomicBoolean](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic/AtomicBoolean.html)
- [AtomicInteger](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic/AtomicInteger.html)
- [AtomicLong](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic/AtomicLong.html)
- [AtomicReference](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic/AtomicReference.html)
- [AtomicIntegerArray](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic/AtomicIntegerArray.html)
- [AtomicLongArray](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic/AtomicLongArray.html)
- [AtomicReferenceArray](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic/AtomicReferenceArray.html)
- [AtomicStampedReference](http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/atomic/AtomicStampedReference.html)

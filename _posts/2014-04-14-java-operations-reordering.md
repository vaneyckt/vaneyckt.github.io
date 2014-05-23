---
layout: post
title: "Java operations reordering"
category: java
---
{% include JB/setup %}

In the absence of synchronization, it is impossible to predict the order in which the operations of a thread will be executed as long as this reordering is not detectable within this thread. Note that it does not matter whether this reordering could be apparent to other threads.

{% gist vaneyckt/ab7025819f7d88d20ecb %}

We would expect the above code to print the number 1. However, it is quite possible for it to print 0 due to a reordering of the operations on lines 17-18. You should therefore never share data between threads without appropriate synchronization.

---
layout: post
title: "Thread.run() vs Thread.start()"
category: java
---
{% include JB/setup %}

I was writing some proof of concept code today and in my haste wrote something not unlike this:

{% gist vaneyckt/98086e082afee8206970 ThreadRun.java %}

It took me a few moments to notice I was calling `Thread.run()`. It turns out this is a perfectly valid thing to do and causes the *Runnable* of the thread to be run inside the currently active thread rather than inside a new thread. I didn't know you could do this :). A simple fix later and everything was working right:

{% gist vaneyckt/98086e082afee8206970 ThreadStart.java %}

---
layout: post
title: "Invocating a shell command from a Java program"
category: java
---
{% include JB/setup %}

I've found there are quite a few ways to do this. Most of them will work just fine right up until you find yourself having to pass arguments with spaces. Here's the easy way of doing it. Note that the `captureOutput` method risks having an infinite loop for processes that don't close after having been invoked. As this code was written for an internal tool that never has to deal with that scenario, this works fine for me, but you've been warned :)

{% gist vaneyckt/28f1df98b761b5e19b23 %}

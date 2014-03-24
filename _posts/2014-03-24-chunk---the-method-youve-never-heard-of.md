---
layout: post
title: "Chunk - the method you've never heard of"
category: ruby
---
{% include JB/setup %}

Sometimes you need some iterating logic that not only depends on the contents of an array but on the order of the elements themselves as well. This is where `chunk` comes in. It's a method that iterates over an array and groups together any consecutive elements that meet a given condition. There are some nice examples of it in the [Ruby documentation](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-chunk).

But what really sold me on the power of this method was [this StackOverflow post](http://stackoverflow.com/a/5544860/1420382). It showcases a really clever use of `chunk` that allows you to get rid of all duplicate consecutive elements in an array with just one line of code. Really impressive stuff.

{% gist vaneyckt/82c5d4f22ab2ea77d0f5 %}

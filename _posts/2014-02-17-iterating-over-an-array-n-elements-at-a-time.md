---
layout: post
title: "Iterating over an array, n elements at a time"
category: ruby
---
{% include JB/setup %}

`each_slice` is one of those methods that is super useful, but that nevertheless doesn't seem to pop up very often. It is perfect for doing things like calculating the average of each pair of elements in an array.

{% gist vaneyckt/0df3dd5cacf994e0147f %}

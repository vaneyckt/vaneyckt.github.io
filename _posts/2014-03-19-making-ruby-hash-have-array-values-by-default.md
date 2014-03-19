---
layout: post
title: "Making Ruby hash have array values by default"
category: ruby
---
{% include JB/setup %}

Making Ruby hash have array values by default

When working with large amounts of data in Ruby I usually find myself using a hash filled with arrays. It tends to end up looking something like this

{% gist vaneyckt/8da2dc0d6d469b3dc5ab wrong.rb %}

I really dislike having to use two lines of code in order to safely enter something in the `output_data` hash. It just looks messy. But luckily we can do this instead

{% gist vaneyckt/8da2dc0d6d469b3dc5ab better.rb %}

The above code initializes every empty hash value to an instance of an empty array. Take note though that this is not the same as calling `output_data.default = []` as that would cause every empty hash value to return the same array object.

{% gist vaneyckt/8da2dc0d6d469b3dc5ab warning.rb %}

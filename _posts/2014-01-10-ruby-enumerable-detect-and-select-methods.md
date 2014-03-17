---
layout: post
title: "Ruby Enumerable detect and select methods"
category: ruby
---
{% include JB/setup %}

Every seems to know the [select method](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-select) in Ruby. It's a method that returns an array of all elements in an Enumerable that match a given condition. However, it also seems to get used a lot in scenarios where the caller only cares about the first match.

In such cases, the [detect method](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-detect) should be used instead. It's very similar to `select`, but instead it returns the first element matching the given condition. I'm sure you'll agree that this is much cleaner than calling `first` on the array returned by `select`.

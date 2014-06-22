---
layout: post
title: "Ruby's lesser known scope rules (and their effect on closures) (2/2)"
category: ruby
---
{% include JB/setup %}

Before we talked about how the `if` statement does not introduce scope in Ruby. When looking deepter into this I found there are several looping constructs that have similar behaviour.

{% gist vaneyckt/b9d99d78631a380715d6 binding.rb %}

So far, so good. However, these are LOOPING constructs and therefore have one more trick up their sleeve. In all these examples the first iteration of the loop wil create the variable; all subsequent iterations will reuse this variable rather than creating a new one. As shown by [this post](http://stackoverflow.com/a/10397030/1420382), this can create very tricky bugs when writing code that uses closures. It's therefore best to try and avoid them when possible.

{% gist vaneyckt/b9d99d78631a380715d6 closures.rb %}

Another reason to avoid these constructs is that by using just one of them you might create problems in other parts of your code as well. The `while` loop in the example below causes the `input` variable to be defined outside the `while` loop. This in turn causes the subsequent closure to give unexpected results.

{% gist vaneyckt/b9d99d78631a380715d6 unexpected.rb %}

We could fix this by renaming the `input` variable of the second example.

{% gist vaneyckt/b9d99d78631a380715d6 renamed.rb %}

---
layout: post
title: "Never forward declare a hash again"
category: ruby
---
{% include JB/setup %}

In many cases you'll find yourself declaring a hash on one line, and writing the code to modify it on the next. The example below is a bit trite, but illustrates the point.

{% gist vaneyckt/240df08d0a936441ef98 before_each_with_object.rb %}

Luckily we can use `each_with_object` to improve on this. At the very start of the first iteration `d` is assigned `{}`. This iteration then goes on to modify `d` before passing it to the next iteration. In this way all changes to `d` are accumulated across all iterations. The method ends by returning `d`.

{% gist vaneyckt/240df08d0a936441ef98 after_each_with_object.rb %}

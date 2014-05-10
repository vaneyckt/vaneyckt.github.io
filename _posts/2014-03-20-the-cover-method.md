---
layout: post
title: "The cover? method"
category: ruby
---
{% include JB/setup %}

Up until now whenever I wanted to check if a value was inside a range I'd write something like `(1..5).to_a.include?(my_value)`. I should have known Ruby allowed for a much nicer way of doing this like so `(1..5).cover?(my_value)`.

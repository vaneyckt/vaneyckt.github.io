---
layout: post
title: "Using closures for breadth-first and depth-first search (2/2)"
category: ruby
---
{% include JB/setup %}

A previous post on this topic showed a closure-based approach for breadth-first and depth-first search. This post is going to highlight a very subtle bug that could sneak into your own closure-centric code. We have gone over this before when talking about Ruby's lesser known scope rules, but it might be good to showcase them again in a real-life scenario.

For reference, this is the correctly functioning code:

{% gist vaneyckt/c87e8e1b7c8d364c48b6 breadth-first.rb %}

However, removing the `.each` loop and replacing it with some code that executes the same logic causes wildly different results to be outputted. What's going on here?

{% gist vaneyckt/9ddb8e54bcebd8a26484 unexpected.rb %}

We've talked before about how the `while` loop does not only not introduce a new scope, but causes any variables declared in the loop to be created during the first iteration, after which these are reused again in subsequent iterations. This surprising behaviour can introduce subtle bugs in any closures that utilize these variables.

We can show this behaviour is the cause of this unexpected output by wrapping the `child_node_A` and `child_node_B` variables inside a block, therefore creating a new scope.

{% gist vaneyckt/9ddb8e54bcebd8a26484 block.rb %}

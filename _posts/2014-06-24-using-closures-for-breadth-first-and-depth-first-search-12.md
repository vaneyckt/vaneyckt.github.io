---
layout: post
title: "Using closures for breadth-first and depth-first search (1/2)"
category: ruby
---
{% include JB/setup %}

I try to avoid recursion when doing tree traversal as recursive code tends to be hard to debug. Instead I've come to favor an approach that involves inserting and removing closures from a double-ended queue (although in Ruby's case you can just use an array). I like this because:

- there's only two small code changes needed to go from breadth-first to depth-first

- you're storing the closures in a double-ended queue rather than on the program stack. This means you don't have to worry about 'Recursion too deep; the stack overflowed' type errors.

- you can query the deque to find out the order of your yet to be executed calls. This information is not accessible when doing regular recursion as it would live in the program stack.

{% gist vaneyckt/c87e8e1b7c8d364c48b6 breadth-first.rb %}

{% gist vaneyckt/c87e8e1b7c8d364c48b6 depth-first.rb %}

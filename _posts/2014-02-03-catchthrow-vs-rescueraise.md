---
layout: post
title: "Catch/throw vs rescue/raise"
category: ruby
---
{% include JB/setup %}

If you're coming from another language, you might be tempted to throw and catch exceptions in Ruby. However, Ruby expects exceptions to be raised and rescued. Catch/throw is really just a slightly tidier version of goto. By throwing a symbol you're telling Ruby to start unwinding the call stack in search for a block labeled with the thrown symbol. This block is then immediately terminated.

This sounds a bit weird, right? I certainly was expecting it to execute the block; not terminate it. As it turns out, the proper usage of catch/throw is a bit non-standard. The best example I've found comes from [phrogz.net](http://phrogz.net/programmingruby/tut_exceptions.html) and goes like this

{% gist vaneyckt/377c135da96c4b3255c6 %}

By wrapping successive calls to `promptAndGet` in a `catch` block, this program will stop as soon as the user responds with '!'. Though the above code doesn't look too bad, just imagine what it would look like with half a dozen catch statements.

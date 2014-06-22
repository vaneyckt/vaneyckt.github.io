---
layout: post
title: "Ruby's lesser known scope rules (1/2)"
category: ruby
---
{% include JB/setup %}

Did you know that Ruby's if statement does not introduce scope? This always seemed a bit weird to me until one day I came across [this post](http://programmers.stackexchange.com/questions/58900/why-if-statements-do-not-introduce-scope-in-ruby-1-9) and learned that this is actually an incredibly powerful feature. It's a bit like having a runtime version of [conditional compilation](http://en.wikipedia.org/wiki/C_preprocessor#Conditional_compilation) baked into the language itself.

{% gist vaneyckt/3b98cb2b0db64f5ff6a4 conditional.rb %}

While looking into this I stumbled across Ruby's [binding method](http://ruby-doc.org/core-2.1.0/Binding.html). This method provides us with a great alternative approach to check whether a new scope is being introduced. We can use it like this:

{% gist vaneyckt/3b98cb2b0db64f5ff6a4 binding.rb %}

---
layout: post
title: "Ruby Enumerator with_index method"
category: ruby
---
{% include JB/setup %}

Sometimes you need to iterate over an array and get both the current element and its index back. In this case you'd use `each_with_index`. However, you could also use `each.with_index` instead. Note that `each_with_index` is an Enumerable method, whereas `with_index` is an Enumerator method. This is important as it allows you to call it on other Enumerators as well.

{% gist vaneyckt/7995628b65af8d9274cd example_a.rb %}

Even better is that `with_index` allows you to specify an initial offset value. So if you have a situation where your index needs to start from 1, you could write something like

{% gist vaneyckt/7995628b65af8d9274cd example_b.rb }

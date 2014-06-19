---
layout: post
title: "The Rails way to get data in a time range"
category: rails
---
{% include JB/setup %}

I'm writing this mostly as a reminder to myself, since I keep forgetting this :)

Don't do this:

{% gist vaneyckt/6926335 wrong.rb %}

Do this instead:

{% gist vaneyckt/6926335 right.rb %}

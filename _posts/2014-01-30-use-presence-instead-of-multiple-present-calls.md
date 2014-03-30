---
layout: post
title: "Use presence() instead of multiple present? calls"
category: rails
---
{% include JB/setup %}

I'm just going to take this [straight from the documentation](http://api.rubyonrails.org/classes/Object.html#method-i-presence). You can replace

{% gist vaneyckt/f38a95e6cc3c7d9bd1b4 before_presence.rb %}

with

{% gist vaneyckt/f38a95e6cc3c7d9bd1b4 after_presence.rb %}

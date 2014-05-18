---
layout: post
title: "Working with time zones, times and dates in Ruby and Rails"
category: rails
---
{% include JB/setup %}

[This](http://danilenko.org/2012/7/6/rails_timezones/) is by far the best explanation I've ever come across. It's definitely worth a read as it not only gives a ton of examples for both times and dates, but a list of best practices as well.

{% gist vaneyckt/a7779cb038d75d3c6de6 %}

What you should take away from this:

- `Time.now` is a Ruby method that does not know about rails time zones and returns the system time
- `.in_time_zone` and `.zone` are ActiveSupport methods for time zone manipulation

Also if you're using the wonderful [chronic gem](https://rubygems.org/gems/chronic), you can use `Chronic.time_class = Time.zone` to specify a time zone.

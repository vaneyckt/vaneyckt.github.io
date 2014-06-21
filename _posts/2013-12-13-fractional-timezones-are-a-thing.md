---
layout: post
title: "Fractional timezones are a thing"
category: general
---
{% include JB/setup %}

Fractional timezones are timezones that have a UTC offset that is a fraction of an hour instead of the usual full hour ([list of timezones](http://en.wikipedia.org/wiki/List_of_time_zones_by_UTC_offset)). This means that if you were to write an app that allows a customer to specify a time and a timezone at which to regularly run a task, you can not simply have your app check for work at the start of every hour. Just something to keep in mind :)

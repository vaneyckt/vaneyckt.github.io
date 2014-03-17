---
layout: post
title: "A step by step guide to fixing Git mistakes"
category: git
---
{% include JB/setup %}

As shown by the code below, you can easily pass ENV vars to a migration

{% gist vaneyckt/7221328 migration.rb %}

{% gist vaneyckt/7221328 code.sh %}

While you should avoid doing this as much as possible, it sometimes can be very handy to add two codepaths to a migration: a slow one that performs safety checks without modifying the database, and a fast one that only gets run after the first one has successfully passed. The value of a given ENV var can then be used to decide which codepath to run.

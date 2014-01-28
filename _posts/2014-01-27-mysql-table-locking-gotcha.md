---
layout: post
title: "MySQL table locking gotcha"
category: rails
---
{% include JB/setup %}

Locking a table with

{% gist vaneyckt/7029349 %}

ensures that only the current connection can [ACCESS](http://dev.mysql.com/doc/refman/5.0/en/lock-tables.html) that table. Other connections will not even be able to read from this table while it is locked!

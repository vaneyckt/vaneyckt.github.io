---
layout: post
title: "Converting your id column to bigint"
category: rails
---
{% include JB/setup %}

We recently had an issue with the auto-increment id of our widgets table about to run out of space. The id was being stored as an int, and the large number of rows in that table would cause all available int numbers to be used up soon. We decided to change the id data type to bigint instead.

We tried an [ActiveRecord approach](https://moeffju.net/blog/using-bigint-columns-in-rails-migrations) at first, but found that this would silently drop the auto-increment property of the column. So we switched to using MySQL commands instead. A couple of interesting things to note here:

- the [WRITE lock](http://dev.mysql.com/doc/refman/5.0/en/lock-tables.html) prevents other sessions from reading from or writing to the table. Otherwise our stored auto-increment value would no longer be correct.
- we wrap everything inside a transaction to ensure the lock will be released no matter what. Take note that the ALTER TABLE command cannot be rolled back as it causes an [implicit commit](http://dev.mysql.com/doc/refman/5.0/en/implicit-commit.html).

{% gist vaneyckt/7194494 %}

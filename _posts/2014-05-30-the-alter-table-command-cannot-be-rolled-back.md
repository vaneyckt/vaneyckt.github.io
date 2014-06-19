---
layout: post
title: "The ALTER TABLE command cannot be rolled back"
category: rails
---
{% include JB/setup %}

I recently came across the migration below. At first sight it looks like everything is okay, but there is actually a very dangerous assumption being made here.

{% gist vaneyckt/7012470 %}

Notice how the conversion code is wrapped inside a transaction. The assumption here is that if something goes wrong the transaction will trigger a rollback. However, an ALTER TABLE command in MySQL causes an [implicit commit](http://dev.mysql.com/doc/refman/5.0/en/implicit-commit.html). This means that a rollback will not undo any changes introduced by ALTER TABLE!

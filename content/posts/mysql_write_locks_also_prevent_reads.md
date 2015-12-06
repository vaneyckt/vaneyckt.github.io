+++
date = "2013-10-17T17:20:45+00:00"
title = "MySQL write locks also prevent reads"
type = "post"
ogtype = "article"
tags = [ "rails", "mysql" ]
+++

Locking a table with

```ruby
table_name = 'widgets'
ActiveRecord::Base.connection.execute("LOCK TABLES #{table_name} WRITE")
```

ensures that [only the current connection can access that table](http://dev.mysql.com/doc/refman/5.0/en/lock-tables.html). Other connections cannot even read from this table while it is locked!

+++
date = "2013-10-16T18:45:12+00:00"
title = "Rails migrations and the dangers of implicit commits"
type = "post"
ogtype = "article"
tags = [ "rails", "mysql" ]
+++

I recently came across the migration below. At first sight it looks like everything is okay, but there is actually a very dangerous assumption being made here.

```ruby
# migration to convert table to utf8
class ConvertWidgetsTableToUtf8Unicode < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      table_name = 'widgets'
      say "converting #{table_name} table to utf8_unicode_ci"

      execute("ALTER TABLE #{table_name} CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci")
      execute("ALTER TABLE #{table_name} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci")
    end
  end
end
```

Notice how the utf8 conversion code is wrapped inside a transaction. The assumption here is that if something goes wrong the transaction will trigger a rollback. However, an `ALTER TABLE` command in MySQL causes an [implicit commit](http://dev.mysql.com/doc/refman/5.0/en/implicit-commit.html). This means that the rollback will not undo any changes introduced by the `ALTER TABLE` command!

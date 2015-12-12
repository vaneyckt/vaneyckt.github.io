+++
date = "2013-10-20T17:19:31+00:00"
title = "The paranoid approach to converting your MySQL database to utf8"
type = "post"
ogtype = "article"
topics = [ "rails", "mysql" ]
+++

Converting all the data in your database can be a nail-biting experience. As you can see from the code below we are doing our best to be super careful. We convert each table separately and before each conversion we store the table's column types and an MD5 hash of every row in the table (we were lucky enough to not have enormous tables). After converting the table we check that no column types or rows were changed. It goes without saying that we do a trial run on a database dump first.

```ruby
require 'set'
require 'digest/md5'

CHARACTER_SET = 'utf8'
COLLATION = 'utf8_unicode_ci'

class ConvertAllTablesToUtf8 < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("LOCK TABLES #{table} WRITE")
          say "starting work on table: #{table}"

          model = table.classify.constantize
          say "associated model: #{model}"

          say 'storing column types information before converting table to unicode'
          column_types_before = model.columns_hash.each_with_object({}) do |(column_name, column_info), column_types_before|
            column_types_before[column_name] = [column_info.sql_type, column_info.type]
          end

          say 'storing set of table data hashes before converting table to unicode'
          table_data_before = Set.new
          model.find_each do |datum|
            table_data_before << Digest::MD5.hexdigest(datum.inspect)
          end

          say 'converting table to unicode'
          execute("ALTER TABLE #{table} CONVERT TO CHARACTER SET #{CHARACTER_SET} COLLATE #{COLLATION}")
          execute("ALTER TABLE #{table} DEFAULT CHARACTER SET #{CHARACTER_SET} COLLATE #{COLLATION}")

          say 'getting column types information after conversion to unicode'
          column_types_after = model.columns_hash.each_with_object({}) do |(column_name, column_info), column_types_after|
            column_types_after[column_name] = [column_info.sql_type, column_info.type]
          end

          say 'getting set of table data hashes after conversion to unicode'
          table_data_after = Set.new
          model.find_each do |datum|
            table_data_after << Digest::MD5.hexdigest(datum.inspect)
          end

          say "checking that column types haven't changed"
          if column_types_before != column_types_after
            raise "Column types of the #{table} table have changed"
          end

          say "checking that data hasn't changed"
          if table_data_before != table_data_after
            raise "Data in the #{table} table has changed"
          end
        ActiveRecord::Base.connection.execute('UNLOCK TABLES')
      end
    end

    execute("ALTER DATABASE #{ActiveRecord::Base.connection.current_database} DEFAULT CHARACTER SET #{CHARACTER_SET} COLLATE #{COLLATION}")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

Note how we lock each table before converting it. If we didn't lock it then new data could be written to the table while we are busy storing MD5 hashes of the rows in preparation for the actual conversion. This, in turn, would cause our migration to complain that new data was present after the conversion had taken place.

We also wrap each table conversion inside a transaction. I've talked before about [how converting a table will cause an implicit commit](http://vaneyckt.io/posts/rails_migrations_and_the_dangers_of_implicit_commits/), meaning that a rollback won't undo any of the changes made by the conversion. So why have a transaction here then? Imagine that an exception were to be raised during our migration. In that case we want to ensure our table lock gets dropped as soon as possible. The transaction guarantees this behavior.

Also, if we weren't so paranoid about checking the before and after data as part of our migration, we could simplify this code quite a bit.

```ruby
CHARACTER_SET = 'utf8'
COLLATION = 'utf8_unicode_ci'

class ConvertAllTablesToUtf8 < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |table|
      say 'converting table to unicode'
      execute("ALTER TABLE #{table} CONVERT TO CHARACTER SET #{CHARACTER_SET} COLLATE #{COLLATION}")
      execute("ALTER TABLE #{table} DEFAULT CHARACTER SET #{CHARACTER_SET} COLLATE #{COLLATION}")
    end

    execute("ALTER DATABASE #{ActiveRecord::Base.connection.current_database} DEFAULT CHARACTER SET #{CHARACTER_SET} COLLATE #{COLLATION}")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

Notice how we can drop the lock as the `ALTER TABLE` command [will prevent all writes to the table while simultaneously allowing all reads](https://dev.mysql.com/doc/refman/5.1/en/alter-table.html).

> In most cases, ALTER TABLE makes a temporary copy of the original table. MySQL waits for other operations that are modifying the table, then proceeds. It incorporates the alteration into the copy, deletes the original table, and renames the new one. While ALTER TABLE is executing, the original table is readable by other sessions. Updates and writes to the table that begin after the ALTER TABLE operation begins are stalled until the new table is ready, then are automatically redirected to the new table without any failed updates. The temporary copy of the original table is created in the database directory of the new table. This can differ from the database directory of the original table for ALTER TABLE operations that rename the table to a different database.

Furthermore, since we now no longer have a lock on our table we can also drop the transaction. This gives us the much-simplified code shown above.

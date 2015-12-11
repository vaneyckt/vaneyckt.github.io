+++
date = "2013-11-01T19:17:56+00:00"
title = "Why is MySQL converting my NULLs to blanks?"
type = "post"
ogtype = "article"
tags = [ "mysql" ]
+++

A while ago I ran into an issue where some records were showing a blank value in a given column. This was a bit weird as a blank value had never been written to that column. After a bit of searching we found that we had a bug that had inadvertently been writing the occasional NULL value to that particular column though. So how did those NULLs get turned into blanks?

It turns out that MySQL can operate in different [server modes](https://dev.mysql.com/doc/refman/5.0/en/sql-mode.html). You can check your server mode by running one of the two commands below. Note that your server mode will be blank by default.

```bash
SHOW GLOBAL VARIABLES where Variable_name = 'sql_mode';
SHOW SESSION VARIABLES where Variable_name = 'sql_mode'
```

Now that we know about server modes we can talk about [data type defaults](https://dev.mysql.com/doc/refman/5.0/en/data-type-defaults.html). Basically, each MySQL column has an implicit default value assigned to it. Under certain circumstances this default value might be used instead of the value you were expecting.

> As of MySQL 5.0.2, if a column definition includes no explicit DEFAULT value, MySQL determines the default value as follows:

> If the column can take NULL as a value, the column is defined with an explicit DEFAULT NULL clause. This is the same as before 5.0.2.

>If the column cannot take NULL as the value, MySQL defines the column with no explicit DEFAULT clause. Exception: If the column is defined as part of a PRIMARY KEY but not explicitly as NOT NULL, MySQL creates it as a NOT NULL column (because PRIMARY KEY columns must be NOT NULL), but also assigns it a DEFAULT clause using the implicit default value. To prevent this, include an explicit NOT NULL in the definition of any PRIMARY KEY column.

> For data entry into a NOT NULL column that has no explicit DEFAULT clause, if an INSERT or REPLACE statement includes no value for the column, or an UPDATE statement sets the column to NULL, MySQL handles the column according to the SQL mode in effect at the time:

> * *If strict SQL mode is enabled, an error occurs for transactional tables and the statement is rolled back. For nontransactional tables, an error occurs, but if this happens for the second or subsequent row of a multiple-row statement, the preceding rows will have been inserted.*
* *If strict mode is not enabled, MySQL sets the column to the implicit default value for the column data type.*

We found that our code was sometimes writing NULLs to a NOT NULL column on a server that was not running in strict mode. This in turn caused our NULLs to silently get changed to blanks as this was the column default value. Mystery solved.

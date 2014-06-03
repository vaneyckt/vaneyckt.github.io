---
layout: post
title: "Using models in Rails migrations (2/2)"
category: rails
---
{% include JB/setup %}

A previous post on this topic highlighted the importance of declaring models in your migrations. However, this can still cause unexpected suprises as there is no guarantee that such a model has a current view of the table it is associated with.

{% gist vaneyckt/a2b27573d74a36500adb wrong.rb %}

Let's say you were to run the migration shown above on an imaginary users table. The migration will run fine, no errors will be thrown, and yet for some reason the `is_early_customer` flag of the first user will not have been set to `true`. The reason for this is that the User model gets told about the columns of the users table at the very start of the `bundle exec rake db:migrate` command. This means that when the migration gets around to executing line 7, the locally declared User model will have no idea the users table now has a new column. In order to get around this we have to call `reset_column_information` after the table has been modified.

{% gist vaneyckt/a2b27573d74a36500adb right.rb %}

While this isn't too bad in itself, it can get trickier when multiple migrations are being executed in a single run as any locally defined models receive their column information at the very start of the run itself; that is to say there is [no implicit calling](http://stackoverflow.com/a/11355761/1420382) of `reset_column_information` at the start of every individual migration! This shows why it is a good idea to always reset the column information of a model before calling any of its methods.

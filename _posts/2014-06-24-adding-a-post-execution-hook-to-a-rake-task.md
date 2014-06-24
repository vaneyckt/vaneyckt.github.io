---
layout: post
title: "Adding a post execution hook to a rake task"
category: ruby
---
{% include JB/setup %}

Rake allows you to append code to an existing rake task by redefining it. Even though the code below looks like it is overwriting the `db:migrate` task, the new code just gets appended to the original task.

{% gist vaneyckt/bc1a499a9d2f9e6793f8 append.rake %}

The above example only runs the `my_new_code` method if the original `db:migrate` task does not throw any exceptions. If you want to ensure `my_new_code` always get run, you need to take a slightly different approach. Rather than appending code, we now need to prepend it.

{% gist vaneyckt/bc1a499a9d2f9e6793f8 prepend.rake %}

Here we use [enhance](http://www.dan-manges.com/blog/modifying-rake-tasks) to add a prerequisite task to `db:migrate`. This prerequisite task adds an [at_exit hook](http://www.ruby-doc.org/core-2.1.2/Kernel.html#method-i-at_exit) to the `db:migrate` task that gets run when the task exits. If we wanted this hook to only be executed upon certain exceptions, we could use the [$! variable](http://www.zenspider.com/Languages/Ruby/QuickRef.html#pre-defined-variables) to access the exception object.

The `enhance` method can also be used to append code to a given rake task when used as shown below.

{% gist vaneyckt/bc1a499a9d2f9e6793f8 alternative_append.rake %}

Many thanks to [kardeiz](http://stackoverflow.com/a/24369751/1420382) for coming up with combining `enhance` with the `at_exit` hook. I don't think I've ever seen that before.

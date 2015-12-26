+++
date = "2014-10-09T16:31:22+00:00"
title = "Adding a post-execution hook to the rails db:migrate task"
type = "post"
ogtype = "article"
topics = [ "rails" ]
+++

A few days ago we discovered that our MySQL database's default character set and collation had been changed to the wrong values. Worse yet, it looked like this change had happened many months ago; something which we had been completely unaware of until now! In order to make sure this didn't happen again, we looked into adding a post-execution hook to the rails `db:migrate` task.

Our first attempt is shown below. Here, we append a post-execution hook to the existing `db:migrate` task by creating a new `db:migrate` task. In rake, when a task is defined twice, the behavior of the new task gets appended to the behavior of the old task. So even though the code below may give the impression of overwriting the rails `db:migrate` task, we are actually just appending a call to the `post_execution_hook` method to it.

```ruby
namespace :db do
  def post_execution_hook
    puts 'This code gets run after the rails db:migrate task.'
    puts 'However, it only runs if the db:migrate task does not throw an exception.'
  end

  task :migrate do
    post_execution_hook
  end
end
```

However, the above example only runs the appended code if the original `db:migrate` task does not throw any exceptions. Luckily we can do better than that by taking a slightly different approach. Rather than appending code, we are going to have a go at prepending it instead.

```ruby
namespace :db do
  def post_execution_hook
    puts 'This code gets run after the rails db:migrate task.'
    puts 'It will ALWAYS run.'
  end

  task :attach_hook do
    at_exit { post_execution_hook }
  end
end

Rake::Task['db:migrate'].enhance(['db:attach_hook'])
```

Here we make use of the [enhance method](http://ruby-doc.org/stdlib-2.0.0/libdoc/rake/rdoc/Rake/Task.html#method-i-enhance) to add `db:attach_hook` as a prerequisite task to `db:migrate`. This means that calling `db:migrate` will now cause the `db:attach_hook` task to get executed before `db:migrate` gets run. The `db:attach_hook` task creates an `at_exit` hook that will trigger our post-execution code upon exit of the `db:migrate` task. This means that our post-execution hook will now get called even when `db:migrate` raises an exception!

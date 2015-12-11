+++
date = "2013-10-29T17:42:28+00:00"
title = "Using environment variables in your migrations"
type = "post"
ogtype = "article"
tags = [ "rails" ]
+++

Recently we had to run a migration that was so slow we couldn't afford the downtime it would cause. In order to get around this, it was decided to put two code paths in the migration: one that was slow and thorough, and one that was quick but didn't perform any safety checks.

The first path would be run on a recent database dump, whereas the latter would be executed directly on the live database once the first had finished without error. This was a lot less crazy than it might sound as the particular table under modification had very infrequent changes.

It was decided to use environment variables to allow for easy switching between code paths. This is what the code ended up looking like.

```ruby
class MyDangerousMigration < ActiveRecord::Migration
  def change
    if ENV['skip_checks'] == 'true'
      # code without safety checks
    else
      # code with safety checks
    end
  end
end
```

This could then be run like so.

```bash
skip_checks=true bundle exec rake db:migrate
```

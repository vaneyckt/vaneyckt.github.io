+++
date = "2013-10-10T19:22:45+00:00"
title = "Retrieving data in a time range with rails"
type = "post"
ogtype = "article"
tags = [ "rails" ]
+++

I'm writing this mostly as a reminder to myself, since I keep forgetting this :)

Instead of:

```ruby
widgets = Widget.where("? <= created_at AND created_at <= ?", time_from, time_to)
```

do this:

```ruby
widgets = Widget.where(:created_at => time_from .. time_to)
```

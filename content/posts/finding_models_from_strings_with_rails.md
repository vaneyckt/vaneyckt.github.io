+++
date = "2013-10-11T16:27:35+00:00"
title = "Finding models from strings with rails"
type = "post"
ogtype = "article"
tags = [ "rails" ]
+++

Imagine you have a Widget model that stores data in a table 'widgets'. At some point in your rails app you find yourself being given a string 'Widget' and are asked to find the Widget model. This can be done like shown here.

```ruby
str = 'Widget'
model = str.constantize
```

However, things get a bit harder when you have multiple Widget model subclasses (Widget::A, Widget::B), all of which are stored in the widgets table. This time around you're given the string 'Widget::A' and are asked to get the Widget model.

In order to solve this we'll need to ask the Widget::A model to give us its table name. If you're following rails conventions you can then in turn use the table name to get the model you need.

```ruby
str = 'Widget'
model = str.constantize.table_name.classify.constantize
```

Note that the above will only work if you've followed rails naming conventions though :).

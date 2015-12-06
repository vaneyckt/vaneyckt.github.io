+++
date = "2013-10-15T16:46:02+00:00"
title = "Iterating over a hash containing arrays"
type = "post"
ogtype = "article"
tags = [ "ruby" ]
+++

Last week I was implementing some auditing functionality in a rails app. At some point I was writing a page that would display how the attributes of a given ActiveRecord object had been changed. One of my colleagues spotted this and pointed out the following neat bit of syntactic sugar in Ruby.

```ruby
changes = {:attribute_a => [1, 2], :attribute_b => [3, 4]}

changes.each do |attribute, (before, after)|
  puts "#{attribute}: #{before} - #{after}"
end
```

I later learned you can even do things like this.

```ruby
data = {:foo => [[1, 2], 3]}

data.each do |key, ((a, b), c)|
  puts "#{key}: #{a} - #{b} - #{c}"
end
```

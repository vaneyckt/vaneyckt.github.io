+++
date = "2013-08-31T20:22:58+00:00"
title = "Regarding if statement scope in Ruby"
type = "post"
ogtype = "article"
tags = [ "ruby" ]
+++

I recently learned that `if` statements in Ruby do not introduce scope. This means that you can write code like shown below and it'll work fine.

```ruby
# perfectly valid Ruby code
if true
  foo = 5
end

puts foo
```

At first this seemed a bit weird to me. It wasn't until I read [this](http://programmers.stackexchange.com/questions/58900/why-if-statements-do-not-introduce-scope-in-ruby-1-9) that I realized Ruby was even more versatile than I had first thought. As it turns out, it is this somewhat unconventional scoping rule that allows us to conditionally replace methods.

```ruby
if foo == 5
  def some_method
    # do something
  end
else
  def some_method
    # do something else
  end
end
```

As well as conditionally modify implementations.

```ruby
if foo == 5
  class someClass
    # ...
  end
else
  module someModule
    # ...
  end
end
```

And that's amazing!

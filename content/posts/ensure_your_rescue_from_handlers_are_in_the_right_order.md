+++
date = "2013-11-11T21:34:16+00:00"
title = "Ensure your rescue_from handlers are in the right order"
type = "post"
ogtype = "article"
topics = [ "rails" ]
+++

Our `rescue_from` handlers used to be defined like shown below. This might look okay to you. At first glance everything looks fine, right?

```ruby
class WidgetsController < ActionController::Base
  rescue_from ActionController::RoutingError, :with => :render_404
  rescue_from Exception,                      :with => :render_500
end
```

Turns out it's not okay at all. Handlers are searched [from bottom to top](http://apidock.com/rails/ActiveSupport/Rescuable/ClassMethods/rescue_from). This means that they should always be defined in order of most generic to most specific. Or in other words, the above code is exactly the wrong thing to do. Instead, we need to write our handlers like shown here.

```ruby
class WidgetsController < ActionController::Base
  rescue_from Exception,                      :with => :render_500
  rescue_from ActionController::RoutingError, :with => :render_404
end
```

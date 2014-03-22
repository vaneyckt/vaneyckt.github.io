---
layout: post
title: "Put your rescue_from handlers in the right order"
category: rails
---
{% include JB/setup %}

Our rescue_from handlers used to be defined like shown below. Looks okay, right?

{% gist vaneyckt/7418421 wrong_order.rb %}

Turns out it's not okay at all. Handlers are searched [from bottom to top](http://apidock.com/rails/ActiveSupport/Rescuable/ClassMethods/rescue_from). This means that they should always be defined in order of most generic to most specific! Or in other words, the above code is exactly the wrong thing to do. Instead we need

{% gist vaneyckt/7418421 right_order.rb %}

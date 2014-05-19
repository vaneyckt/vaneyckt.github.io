---
layout: post
title: "Cleaner rspec"
category: rails
---
{% include JB/setup %}

Use `instance_double` instead of `double` when creating test doubles. As shown [here](https://relishapp.com/rspec/rspec-mocks/v/3-0/docs), the latter will prevent you from adding stubs and expectations for methods that do not exist or that have an invalid number of parameters.

{% gist vaneyckt/1c56e1db56dae9e4e6e7 double.rb %}

Examples of the new stub and message expectations syntax. The code was taken from [here](http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax), while the reasons for these changes can be found [here](http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax).

{% gist vaneyckt/1c56e1db56dae9e4e6e7 syntax.rb %}

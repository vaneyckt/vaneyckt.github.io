---
layout: post
title: "Cleaner rspec tests"
category: rails
---
{% include JB/setup %}

Some rspec improvements I came across today:

- use `instance_double` instead of `double` when creating test doubles. As shown [here](https://relishapp.com/rspec/rspec-mocks/v/3-0/docs), the latter will prevent you from adding stubs and expectations for methods that do not exist or that have an invalid number of parameters.

{% gist vaneyckt/1c56e1db56dae9e4e6e7 double.rb %}

- use the new stub and message expectations syntax. The code examples below were taken from [this page](http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax). Additional information about the underlying reasons for these changes can be found [here](http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax).

{% gist vaneyckt/1c56e1db56dae9e4e6e7 syntax.rb %}

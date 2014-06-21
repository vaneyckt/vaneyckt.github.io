---
layout: post
title: "Use rspec instance_double instead of double"
category: rails
---
{% include JB/setup %}

Use `instance_double` instead of `double` when creating test doubles. As shown [here](https://relishapp.com/rspec/rspec-mocks/v/3-0/docs), the latter will prevent you from adding stubs and expectations for methods that do not exist or that have an invalid number of parameters.

{% gist vaneyckt/1c56e1db56dae9e4e6e7 double.rb %}

---
layout: post
title: "Calling FactoryGirl methods without prefacing with 'FactoryGirl'"
category: rails
---
{% include JB/setup %}

This is just something I came across recently. Up until now I would always call FactoryGirl methods by writing something like `FactoryGirl.create`. However, if you add `config.include FactoryGirl::Syntax::Methods` to your `spec_helper.rb` file, you can just write `create` instead.

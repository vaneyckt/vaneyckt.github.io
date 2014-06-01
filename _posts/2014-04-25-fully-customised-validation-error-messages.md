---
layout: post
title: "Fully customised validation error messages"
category: rails
---
{% include JB/setup %}

I recently came across a model that had a `user_id` field with the following validation:

`validates :user_id, :length => { :minimum => 5 }`

Whenever someome tried to use a `user_id` that was too short, rails would respond with `User is too short (minimum is 5 characters)`. It looked like rails was assuming that `user_id` was a foreign key to a Users table and was modifying its error message accordingly. However, `user_id` was not a foreign key at all; instead it was just a regular `varchar(255)` column.

After a bit of searching I found that you can use [locales](http://stackoverflow.com/a/2859275/1420382) to set humanized names as well as custom error messages for models:

{% gist vaneyckt/8040afa3b95a412ba6bb %}

This now gives us the error message `User Id prefers the term 'vertically challenged'`.

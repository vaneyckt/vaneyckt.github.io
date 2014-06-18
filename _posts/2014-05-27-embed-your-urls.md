---
layout: post
title: "Embed your urls"
category: rails
---
{% include JB/setup %}

If you need to pass any urls from your server side logic to your client side logic (e.g. rails server code to javascript) then the cleanest way is to embed them as hidden input fields on the web page in question. Rather than writing the actual urls, you should use the named route functionality provided by rails as this offers more flexibility. You can get a list of your named routes by running `bundle exec rake routes` in your rails app folder.

When the page gets rendered, these named routes will get converted to actual urls by ERB. On top of this, rails route helpers also make it easy to add query params to your url just by writing something like `my_named_route_path(:foo => :bar)`.

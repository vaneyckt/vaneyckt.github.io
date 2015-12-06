+++
date = "2013-10-13T14:55:23+00:00"
title = "URI.js and URL manipulation in rails"
type = "post"
ogtype = "article"
tags = [ "rails" ]
+++

Manipulating urls in javascript often ends up being an exercise in string interpolation. This rarely produces good looking code. Recently we've started enforcing the use of the [URI.js library](https://medialize.github.io/URI.js/) to combat this.

Our new approach has us embed any necessary urls in hidden input fields on the web page in question. Rather than hardcoding these urls, we use the named route functionality offered by rails as this provides more flexibility. When the page gets rendered, these named routes are converted to actual urls through ERB templating. The embedded urls can then be fetched by javascript code and manipulated with URI.js.

It's no silver bullet, but the resulting code is a lot more readable.

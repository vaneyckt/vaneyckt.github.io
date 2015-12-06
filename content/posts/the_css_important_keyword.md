+++
date = "2013-10-12T15:03:23+00:00"
title = "The css !important keyword"
type = "post"
ogtype = "article"
tags = [ "css" ]
+++

Today I learned about the css !important keyword. I was trying to change the way code snippets (gists) were being displayed on a site, but found my css rules being ignored.

As it turned out, the javascript snippets used for embedding gists were adding an additional css stylesheet to the page. Since this stylesheet was getting added after my own stylesheet, its rules had priority over my own. The solution was to add `!important` to my own rules.

```css
.gist-data {
  border-bottom: 1px !important;
}
```

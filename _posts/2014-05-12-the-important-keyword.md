---
layout: post
title: "The !important keyword"
description: ""
category: css
---
{% include JB/setup %}

A while ago I was trying to change the way gists are displayed on another blog, but found my css rules being ignored. It turned out that the javascript snippets for embedding gists were adding an additional css stylesheet to the site. Since this gist stylesheet was getting added after my own stylesheets, its rules had priority over my own. The solution here was to add `!important` to my own rules in order to give them priority.

{% gist vaneyckt/6947818 %}

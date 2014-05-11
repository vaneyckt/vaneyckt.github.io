---
layout: post
title: "Testing for regex match"
category: javascript
---
{% include JB/setup %}

There's several ways to do this in javascript, but the [RegExp test method](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp/test) is probably the cleanest as - unlike the [String search](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/search) and [String match](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/match) methods - it actually returns `true` or `false`.

{% gist vaneyckt/348d2698777e3ec61df3 %}

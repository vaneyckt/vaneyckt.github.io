---
layout: post
title: "Converting a decimal int to a hex string with leading zeroes"
category: java
---
{% include JB/setup %}

The code below will create a string containing the hex value of a given integer, adding leading zeroes if the hex value is less than 5 characters long. It will even handle negative numbers correctly.

{% gist vaneyckt/325b240c58d012708096 %}

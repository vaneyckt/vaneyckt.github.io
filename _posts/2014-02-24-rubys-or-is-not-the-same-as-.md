---
layout: post
title: "Ruby's or is not the same as ||"
category: ruby
---
{% include JB/setup %}

`or` was never meant to be used as a substitute for `||`. Instead `or` (and `and`) originate from Perl and were always meant to be used as [control flow operators](http://devblog.avdi.org/2010/08/02/using-and-and-or-in-ruby). Nevertheless it keeps being misused. The problem is that the `or` operator has very low precedence, causing statements like `x = y or z` to be interpreted as `(x = y) or z`. This can lead to some very interesting bugs.

{% gist vaneyckt/f4eacce6ae2e98a6f13a %}

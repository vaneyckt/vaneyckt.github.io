---
layout: post
title: "Concurrency and escaping 'this' references (2/2)"
category: java
---
{% include JB/setup %}

Some more writing about [reference escaping](http://www.ibm.com/developerworks/java/library/j-jtp0618/index.html).

Letting another object get a hold of the 'this' reference of an object under construction isn't always a bad thing. Depending on what the object will do with the reference everything could be just fine. Unfortunately you don't always have a say about this, so in general it is best to not let the 'this' reference escape in the first place.

{% vaneyckt/bedc071676ebc32f46a1 safe.java %}
{% vaneyckt/bedc071676ebc32f46a1 unsafe.java %}

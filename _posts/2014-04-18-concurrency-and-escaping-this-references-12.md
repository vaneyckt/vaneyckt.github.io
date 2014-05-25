---
layout: post
title: "Concurrency and escaping 'this' references (1/2)"
category: java
---
{% include JB/setup %}

A quick write-up of [this article on reference escaping](http://www.ibm.com/developerworks/java/library/j-jtp0618/index.html).

You should always take care to not expose an object's `this` reference to another thread before its constructor has completed. Constructors are not ordinary methods; they have special semantics for initialization safety. An object is assumed to be in a predictable, consistent state after the constructor has completed, and publishing a reference to an incompletely constructed object is dangerous.

Some examples that expose the `this` reference before the constructor has completed:

{% gist vaneyckt/bf9e8c802946a560affd explicit.java %}
{% gist vaneyckt/bf9e8c802946a560affd implicit.java %}
{% gist vaneyckt/bf9e8c802946a560affd threadWithThis.java %}
{% gist vaneyckt/bf9e8c802946a560affd threadWithRunnable.java %}

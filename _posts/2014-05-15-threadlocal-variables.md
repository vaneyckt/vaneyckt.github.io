---
layout: post
title: "ThreadLocal variables"
category: java
---
{% include JB/setup %}

I recently came across [ThreadLocal](http://docs.oracle.com/javase/6/docs/api/java/lang/ThreadLocal.html) variables in Java. These variables differ from their normal counterparts in that each thread that accesses one (via its `get` or `set` method) has its own, independently initialized copy of the variable. Such instances are typically private static fields in classes that wish to associate state with a thread.

Notice how the example below overrides the `initialValue()` method. This method will be invoked the first time a thread accesses the *ThreadLocal* variable with the `get()` method, unless the thread has previously invoked the `set()` method. Normally, this method is invoked at most once per thread, but it may be invoked again in case of subsequent invocations of `remove()` followed by `get()`.

{% gist vaneyckt/770ecd28cf7daae98cac UniqueThreadIdGenerator.java %}

** When to use it **

The [javarevisited website](http://javarevisited.blogspot.ie/2012/05/how-to-use-threadlocal-in-java-benefits.html) mentions several scenarios that can benefit from using *ThreadLocal* variables:

- *ThreadLocal* variables are fantastic for implementing Per Thread Singleton classes or per thread context information, e.g. a transaction id.

- If you want to preserve or carry information from one method call to another you can carry it by using *ThreadLocal*. This can provide immense flexibility as it allows you to pass data around without having to add additional parameters to your existing method declarations.

-  When you have an object that is not thread safe, but you want to avoid synchronizing access to it, you can use *ThreadLocal* to give each thread its own instance of that object. You'll often see this done with [SimpleDateFormat](http://stackoverflow.com/a/817926/1420382).

{% gist vaneyckt/770ecd28cf7daae98cac DateFormatter.java %}

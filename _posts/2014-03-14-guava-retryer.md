---
layout: post
title: "Guava Retryer"
category: java
---
{% include JB/setup %}

Sometimes you want to make sure a function call gets retried until a given condition is met. However, you also want to ensure that this call doesn't get retried forever, as that might cause your program to hang. This is exactly what the [Guava Retrying Extension](https://github.com/rholder/guava-retrying) was designed for.

In this example we have a unit test that needs to call a method several times in a row until it returns `true`. However, if it does not do so within 3 seconds, the test should be marked as failed.

{% gist vaneyckt/0e69ca620f54d7f5f6e8 %}

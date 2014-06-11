---
layout: post
title: "Moving your Android unit tests to a library"
category: android
---
{% include JB/setup %}

When you develop both a paid and a free version of an Android app, you're going to want to put all the shared logic code into an Android library. Often these versions don't just have similar logic in common, but a large number of unit tests as well. Here's how you can order your code to reduce unit test duplication as much as possible.

Put a UnitTestsBase class in your Android library to hold all your shared unit tests.

{% gist vaneyckt/61ae600a2a317ce237d2 UnitTestsBase.java %}

You can then simply have the unit tests of the free and paid versions inherit this class like shown below. This way all your shared unit tests can live in your Android library, but still get run as part of the test suite of either version without any unit test duplication.

{% gist vaneyckt/61ae600a2a317ce237d2 FreeUnitTests.java %}

{% gist vaneyckt/61ae600a2a317ce237d2 PaidUnitTests.java %}

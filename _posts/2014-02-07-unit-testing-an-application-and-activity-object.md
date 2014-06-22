---
layout: post
title: "Unit testing an Application and Activity object"
category: android
---
{% include JB/setup %}

A lot of my unit tests require both an Activity and an Application object to be present. I figured using [ApplicationTestCase](http://developer.android.com/reference/android/test/ApplicationTestCase.html) was the right way to go, but it turns out that while this does indeed cause an Application to be created, it does not instantiate any Activities.

Instead I needed to switch to [ActivityInstrumentationTestCase2](http://developer.android.com/reference/android/test/ActivityInstrumentationTestCase2.html). This creates a single specified Activity as well as an Application object. I wish the documentation was a bit more clear on this.

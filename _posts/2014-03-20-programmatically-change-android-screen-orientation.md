---
layout: post
title: "Programmatically change Android screen orientation"
category: android
---
{% include JB/setup %}

A lot of digital ink has been spilled on this subject, so I figured it might be worth to briefly talk about this. You can either change the orientation through ADB or through an app. While the ADB approach is the easiest, it might not work on all devices or on all Android versions. For example, the `dumpsys` output of a Kindle Fire is different than the output of a Samsung Galaxy S4, so you might need to tweak the grepping of the output.

{% gist vaneyckt/31277ed6c939a9f4c120 adb.sh %}

If you don't want to use ADB and prefer an Android app to change the orientation instead, you can just use these commands.

{% gist vaneyckt/31277ed6c939a9f4c120 app.java %}

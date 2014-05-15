---
layout: post
title: "Storing default values in Android"
category: android
---
{% include JB/setup %}

Sometimes you'll find yourself in a position where you'll need to use the same set of default values in both your code and xml. In order to avoid having to repeat your default values, you should follow [this approach](http://stackoverflow.com/questions/2767354/default-value-of-android-preference) and define your default values in a resources file:

{% gist vaneyckt/a1966520b81cbba4c885 defaults.xml %}

You can then easily refer to them in other xml files:

{% gist vaneyckt/a1966520b81cbba4c885 layout.xml %}

As well as access them from your code:

{% gist vaneyckt/a1966520b81cbba4c885 activity.java %}

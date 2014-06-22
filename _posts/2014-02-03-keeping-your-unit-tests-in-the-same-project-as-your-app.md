---
layout: post
title: "Keeping your unit tests in the same project as your app"
category: android
---
{% include JB/setup %}

My initial unit testing experience with Android led me to believe that unit tests could only exist in a separate project. This turns out to not be the case. It is in fact very simple to put your tests in the same project as your app. You just need make sure the following lines are present in your `AndroidManifest.xml` file

{% gist vaneyckt/4cb54fc32c5ea9042660 %}

Don't worry if your IDE tells you it can't resolve the specified `targetPackage` value; it should work fine.

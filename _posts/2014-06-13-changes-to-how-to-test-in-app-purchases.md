---
layout: post
title: "Changes to how to test In App Purchases"
category: android
---
{% include JB/setup %}

It used to be possible to test In App Purchases by uploading an alpha version of your app in draft mode to the [Google Play Developer Console](https://play.google.com/apps/publish). However, due to a recent change it is now no longer possible to perform an IAP in draft mode; performing an IAP in such an unpublished app will cause the IAP to fail with a generic error message. Instead you are now asked to publish your app to an alpha (or beta) distribution channel.

Publishing an alpha (or beta) version of your app will cause it to become visible to a whitelist of users who can then download and test it. Note that this whitelist needs to be composed of Google Group emails or Google+ Community urls. It does not seem possible to add individual emails to a whitelist.

More information on this can be found in the [recently updated Android documentation](http://developer.android.com/google/play/billing/billing_testing.html#draft_apps).

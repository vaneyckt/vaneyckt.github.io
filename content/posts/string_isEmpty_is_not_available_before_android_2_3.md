+++
date = "2014-05-14T20:14:48+00:00"
title = "String.isEmpty() is not available before Android 2.3"
type = "post"
ogtype = "article"
topics = [ "android" ]
+++

Today I learned that Android API level 8 and lower does [not support String.isEmpty()](http://stackoverflow.com/questions/5244927/cant-call-string-isempty-in-android). Keep this is mind when you’re working on an app that needs to be able to run on older phones and use `String.length() == 0` instead.

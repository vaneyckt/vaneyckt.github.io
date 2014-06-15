---
layout: post
title: "Using Robot on OS X"
category: java
---
{% include JB/setup %}

The [Java Robot class](http://docs.oracle.com/javase/7/docs/api/java/awt/Robot.html) is super helpful for when you want to fake user input. With just a few lines of code you can have a program pretend to move the mouse around or type on the keyboard. However, there do seem to be a few guidelines that need to be followed in order to get a bug free program:

- make sure to set `robot.setAutoDelay(40)`
- make sure to set `robot.setAutoWaitForIdle(true)`
- make sure to call `robot.keyRelease` after every `robot.keyPress`
- make sure to call `robot.mouseRelease` after every `robot.mousePress`

These guidelines are probably somewhat excessive, but they did transform my half-working program into a fully-working one in no time. Many thanks to [Alvin Alexander](http://alvinalexander.com/java/java-robot-class-example-mouse-keystroke) for writing this one up.

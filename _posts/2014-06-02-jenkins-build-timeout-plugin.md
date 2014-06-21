---
layout: post
title: "Jenkins build timeout plugin"
category: jenkins
---
{% include JB/setup %}

Well it finally happened. One of our nightly builds got stuck and caused a pileup of other builds during the night. Luckily Jenkins has the excellent [Build Timeout plugin](https://wiki.jenkins-ci.org/display/JENKINS/Build-timeout+Plugin). This plugin adds a Timeout stanza to the Build Environment section of every job. You can use this to specify a timeout strategy as well as a set of actions you want taken. We use it to cancel and fail any build that runs for more than an hour.

---
layout: post
title: "Debugging Ubuntu Upstart jobs"
description: "linux"
---
{% include JB/setup %}

Ubuntu Upstart jobs are a great way to manage services that need to become available upon boot. However, I recently got to experience first hand just how hard they can be to debug. Luckily I came across [this post](http://askubuntu.com/a/116058).

By putting `console log` in your Upstart job, all its stdout/stderr output will end up in `/var/log/upstart/<job>.log`. You can then use `tail -f` to help you debug your job.

---
layout: post
title: "Showing the differences between two branches"
category: git
---
{% include JB/setup %}

A reminder to myself about a command that I don't get to use very often, but that can be handy when trying to troubleshoot git issues on an unfamiliar codebase.

Show differences between 2 branches:

`git diff branch1..branch2`

Show all files that contain a difference between 2 branches:

`git diff --name-status branch1..branch2`

---
layout: post
title: "Aspell: a command line spell checker"
category: linux
---
{% include JB/setup %}

I was looking for an easy way to check the spelling of all posts in this blog and came across [aspell](http://aspell.net). After a quick read through the documentation, I can now check the spelling of all files in the `_posts` folder with just a single command:

`ls | xargs cat | aspell list | sort | uniq`

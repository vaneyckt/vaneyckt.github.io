---
layout: post
title: "The missing Git Hooks documentation"
category: git
---
{% include JB/setup %}

A colleague recently pointed me to [this](http://longair.net/blog/2011/04/09/missing-git-hooks-documentation). As it turns out, different git hooks have very different current working directories and available environment variables. Being unaware of this can lead to surprising difficulties when writing hook scripts.

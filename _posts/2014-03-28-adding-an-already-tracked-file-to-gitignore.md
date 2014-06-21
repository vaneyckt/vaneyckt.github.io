---
layout: post
title: "Adding an already tracked file to .gitignore"
category: git
---
{% include JB/setup %}

When adding an already tracked file to `.gitignore`, you first need to stop tracking it by running `git rm --cached <file>`. Forgetting to do so will cause the file to not be ignored.

---
layout: post
title: "Reset just one file to its committed state"
category: git
---
{% include JB/setup %}

Most Git users know that `git reset --hard` can be super useful for resetting every tracked file in your working directory to its committed state. There seem to be a lot fewer people who know the same can be done on a per file basis with `git checkout <file>`. Admittedly this command feels a bit weird as `git checkout` is usually associated with changing branches rather than modifying files.

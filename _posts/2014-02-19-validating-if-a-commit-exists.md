---
layout: post
title: "Validating if a commit exists"
category: git
---
{% include JB/setup %}

Quite a few people think that checking the return value of `git rev-parse --verify <commit>` allows you to tell whether a given commit is present in a repository. Unfortunately, `git rev-parse --verify` only verifies whether the specified commit param has a valid syntax. [It does not check whether this commit actually exists!](http://git.661346.n2.nabble.com/Bug-in-quot-git-rev-parse-verify-quot-td7580929.html)

You should check whether your commit is present in a given branch instead. This can be done by inspecting the return value of `git rev-list <branch> | grep <commit>` or by checking the output of `git merge-base <commit> <branch>`.

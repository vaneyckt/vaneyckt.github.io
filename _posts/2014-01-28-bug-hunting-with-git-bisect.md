---
layout: post
title: "Bug hunting with git bisect"
category: git
---
{% include JB/setup %}

A while ago I was looking into what looked like a simple bug. It all seemed straightforward enough, so I did a quick grep of the codebase, found three pieces of code that looked like likely culprits, made some modifications, tried to trigger the bug, and found that absolutely nothing had changed. Half an hour and a lot of additional digging later I was stumped. I had no idea what was going on.

It was at this point that I remembered `git bisect`. This git command asks you to specify two commits: one where things are working, and another one were things are broken. It then does a binary search across the range of commits in between these two. Each search step asks you whether the current commit contains broken code or not, after which it automatically selects the next commit for you. There's a great tutorial over [here](http://webchick.net/node/99).

It took me all of five minutes to find and fix the bug this way. I can safely say that it would have taken me ages to track down this particular bit of offending code, as it ended up being located in a custom bug fix for a third party library.

+++
date = "2013-11-04T20:02:14+00:00"
title = "Bug hunting with git bisect"
type = "post"
ogtype = "article"
topics = [ "git" ]
+++

Today I was looking into what I thought was going to be a simple bug. The problem seemed straightforward enough, so I did a quick grep of the codebase, found three pieces of code that looked like likely culprits, made some modifications, triggered the bug, and found that absolutely nothing had changed. Half an hour and a lot of additional digging later I was stumped. I had no idea what was going on.

It was at this point that I remembered `git bisect`. This git command asks you to specify two commits: one where things are working, and another one where things are broken. It then does a binary search across the range of commits in between these two. Each search step asks you whether the current commit contains broken code or not, after which it automatically selects the next commit for you. There's a great tutorial over [here](http://webchick.net/node/99).

```bash
$ git bisect start
$ git bisect good rj6y4j3
$ git bisect bad 2q7f529
```

It took me all of five minutes to discover the source of the bug this way. I can safely say that it would have taken me ages to track down this particular bit of offending code as it was located in a custom bug fix for a popular third party library (I'm looking at you [Sentry](https://github.com/getsentry/raven-ruby)).

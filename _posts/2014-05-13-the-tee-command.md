---
layout: post
title: "The tee command"
category: linux
---
{% include JB/setup %}

I rarely use [tee](http://manpages.ubuntu.com/manpages/lucid/man1/tee.1.html) so I always end up having to look up its details. Note to myself, next time just read[this](http://stackoverflow.com/questions/764463/unix-confusing-use-of-the-tee-command) instead. Especially the last bit about `sudo echo "foo bar" > /path/to/some/file` and `echo "foo bar" | sudo tee -a /path/to/some/file`.

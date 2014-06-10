---
layout: post
title: "The tee command"
category: linux
---
{% include JB/setup %}

I rarely use [tee](http://manpages.ubuntu.com/manpages/lucid/man1/tee.1.html) so I always end up having to look up its details. Next time I should just read [this](http://en.wikipedia.org/wiki/Tee_(command)), [this](http://www.linuxandlife.com/2013/05/how-to-use-tee-command.html) and [this](http://stackoverflow.com/questions/764463/unix-confusing-use-of-the-tee-command).

Basically this command just writes its stdin to one or more files, while simultaneously duplicating it to its stdout. This makes it easy to log the output of the individual stages in a multistage command like shown here.

`$ ls ~ | tee stage1.txt | grep 'foo' | tee stage2.txt | sort`

It can also be used to echo data to a file that requires sudo permissions. In this type of scenario the following command won't work due to the redirection getting called with a regular user.

`$ sudo echo "foo bar" > /path/to/some/file`

We'll need to rewrite this command like shown here instead.

`$ echo "foo bar" | sudo tee -a /path/to/some/file`

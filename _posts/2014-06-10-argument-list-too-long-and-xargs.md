---
layout: post
title: "'Argument list too long' and xargs"
category: linux
---
{% include JB/setup %}

This is another one of those commands I see popup from time to time, and while I've always had a pretty decent idea of what it does, it is nevertheless a good idea to write it down properly. There's a great write-up of `xargs` on [wikipedia](http://en.wikipedia.org/wiki/Xargs), so I'm more or less just going to be repeating what's already there.

Some linux commands can accept stdin as a parameter by using a pipe, while others will only pay attention to their arguments. In the case of the latter we can try to work around this restriction by using a subshell as shown here.

{% gist vaneyckt/52484a98b47d32cc75fd subshell.sh %}

Unfortunately this command might fail with 'Argument list too long' depending on the number of files returned by `find`. This is where `xargs` comes in handy. The `xargs` command will split its stdin into several sublists that are guaranteed to be smaller than the max number of allowed arguments. Each sublist can then be used as a set of arguments for a specified command.

{% gist vaneyckt/52484a98b47d32cc75fd xargs.sh %}

In this example `xargs` splits the list of found files into several sublists, and then calls `rm` once for each of these. Note that it does not call `rm` once for every element! The `-0` is recommended when working with filenames, as these can contain blanks and/or newlines which `xargs` would otherwise use as separators.

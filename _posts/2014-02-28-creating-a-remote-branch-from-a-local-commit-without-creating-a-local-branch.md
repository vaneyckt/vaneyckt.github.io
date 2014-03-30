---
layout: post
title: "Creating a remote branch from a local commit without creating a local branch"
category: git
---
{% include JB/setup %}

For example, you want to push local commit `b7593fcf35` from the local `master` branch to a remote `foobar` branch without having to create a local `foobar` branch.

{% gist vaneyckt/1c8c30d70e49d66a4b0a remote_branch %}

This can be really handy for certain scripting operations. You'll often want to overwrite the remote `foobar` branch the next time the script gets called. So you might want to use this instead.

{% gist vaneyckt/1c8c30d70e49d66a4b0a remote_branch_push %}

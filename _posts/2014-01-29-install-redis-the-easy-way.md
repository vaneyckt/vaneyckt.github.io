---
layout: post
title: "Install redis the easy way"
category: devops
---
{% include JB/setup %}

Install redis and add it to upstart all in one go

{% gist vaneyckt/b0953ee45db0b73b5276 %}

Interesting things in this script:

* `sudo useradd --system --user-group --shell /bin/false redis` creates a redis [system user](http://linux.die.net/man/8/useradd) (no home directory, can't login) with a corresponding redis group
* `instance \${NAME}` causes upstart to create a [named instance](https://blueprints.launchpad.net/upstart/+spec/named-instances). Multiple uniquely named redis instances can be created by invoking the same upstart script multiple times with a different name param.
* `expect fork` provides a [neat way](http://upstart.ubuntu.com/cookbook/#expect) for dealing with processes that fork in order to daemonize themselves
* `\$` is needed as otherwise the script will try to evaluate `${NAME}` before putting the text in an upstart script at `/etc/init/redis-server.conf`

---
layout: post
title: "SSH Config File"
category: linux
---
{% include JB/setup %}

SSH config files are great. You place one of them in ~/.ssh and all of a sudden you can log into a machine by typing $ ssh dev.
{% gist vaneyckt/dc42de3b101583e4c7d7 config %}

However, I was never quite sure what ForwardAgent yes actually did. Some [quick](https://help.github.com/articles/using-ssh-agent-forwarding) [googling](http://www.unixwiz.net/techtips/ssh-agent-forwarding.html) later, it turns out that it allows a chain of ssh connections to forward key challenges back to the original agent, obviating the need for passwords or private keys on any intermediate machines.

Looking into this I also stumbled across [this page](http://nerderati.com/2011/03/simplify-your-life-with-an-ssh-config-file/), which has a great example of using an SSH config to create a tunnel. Turns out you can just add something like this to your config file
{% gist vaneyckt/dc42de3b101583e4c7d7 tunnel %}

and then you can setup a tunnel as a background process by running $ ssh -f -N tunnel. All traffic directed to your local port 9906 will now automatically get forwarded to port 3306 of database.example.com.

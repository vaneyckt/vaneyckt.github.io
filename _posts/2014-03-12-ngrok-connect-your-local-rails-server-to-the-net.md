---
layout: post
title: "Ngrok: connect your local rails server to the net"
description: linux
---
{% include JB/setup %}

Lately I've been working on an app that needs to be able to react to Github hooks. Writing code for a feature that requires input from another platform can be a bit of an ordeal; it usually requires you to deploy your half-finished app to a webserver somewhere so you can check if everything works as intended. Wouldn't it be nice if you could skip this deployment phase and safely expose your app from your computer instead?

Luckily there now is a free service that does exactly this: [ngrok](https://ngrok.com/). Ngrok will create a subdomain of the form `<your_subdomain>.ngrok.com` for you and will then setup an ssh tunnel between port 80 on this subdomain and a port of your choosing on your local machine. It's a great way for making the app you're working on available on the net without the hassle of having to do a real deploy.

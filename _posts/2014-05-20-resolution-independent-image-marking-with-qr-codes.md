---
layout: post
title: "Resolution independent image marking with QR codes"
category: general
---
{% include JB/setup %}

We have this Android app that displays user specified images at regular time intervals. We were trying to come up with a foolproof way to test whether the right images were being displayed at the right times across a whole range of devices.

That doesn't seem very hard, does it? Just take a bunch of screenshots at regular intervals and check whether the captured images match the specified ones. Unfortunately we are talking about 50+ android devices, all of which could have different resolutions as well as unique anti-aliasing filters. This makes comparing images far from a trivial problem.

We also weren't allowed to choose the images ourselves; so we couldn't just use a completely red or a completely green image to get around the image comparison problem. We were however allowed to make slight modifications to the images. This is where one of my colleagues came up with the brilliant idea to simply add QR codes to the images. QR codes were pretty much designed to be readable regardless of resolution and illumination, and are thus absolutely perfect for this.

Java has the excellent [ZXing library](https://github.com/zxing/zxing) for reading QR codes. Just add [core-3.1.0.jar](http://repo1.maven.org/maven2/com/google/zxing/core/3.1.0/core-3.1.0.jar) and [javase-3.1.0.jar](http://repo1.maven.org/maven2/com/google/zxing/javase/3.1.0/javase-3.1.0.jar) to your java project, and the following code should do the job.

{% gist vaneyckt/d8c0fc1faa8b18320dba %}

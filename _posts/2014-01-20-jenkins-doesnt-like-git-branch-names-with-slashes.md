---
layout: post
title: "Jenkins doesn't like git branch names with slashes"
category: jenkins
---
{% include JB/setup %}

When digging into why the Jenkins CI machine had a build failing with the dreaded

`ERROR: Couldn't find any revision to build. Verify the repository and branch configuration for this job.`

I came to the realization that the Jenkins Git plugin can't handle branch names with slashes in it. While this is not a super big deal, it would have been nice to have a more descriptive error message.

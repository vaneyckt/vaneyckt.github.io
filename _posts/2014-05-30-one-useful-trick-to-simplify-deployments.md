---
layout: post
title: "One useful trick to simplify deployments"
category: general
---
{% include JB/setup %}

It's a good thing to make sure that as few things as possible can go wrong when doing a deployment. We recently introduced a new rule that states that all migrations that can only be run safely after the new code has hit the servers (e.g. migrations that remove columns) should be moved to the next release.

Or to put it another way, we only want to run migrations that play nice with both the current and the new code. Such an approach greatly increases the likelihood that any problematic code changes can simply be reverted without having to roll back any migrations.

Hopefully we'll be pushing for [John Carmack's Parallel Implementations approach](http://www.altdev.co/2011/11/22/parallel-implementations) next :).

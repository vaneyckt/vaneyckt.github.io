---
layout: post
title: "Use present? instead of negating blank?"
category: rails
---
{% include JB/setup %}

I come across `!foo.blank?` on a regular basis. It's much nicer to use `foo.present?` instead.

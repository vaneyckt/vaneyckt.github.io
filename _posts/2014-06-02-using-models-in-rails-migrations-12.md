---
layout: post
title: "Using models in Rails migrations (1/2)"
category: rails
---
{% include JB/setup %}

Sometimes I'll see a migration that assumes the existence of certain models. This is a recipe for disaster as models tend to come and go, but migrations are forever. A migration is something you write once and then don't touch anymore. Models on the other hand are always evolving: they can get renamed, their relationships to other models can change, they can have new methods added or old methods removed, ...

This could cause a new hire trying to setup a local application database by running all migrations to hit a spot of trouble as the model logic relied upon by some older migrations might no longer be there. Or perhaps you would like to reset your local database by running `bundle exec rake db:migrate:reset` and end up staring at a screen filled with errors instead.

Luckily the solution for this is straightforward. You should always declare any models needed by your migration in the migration itself along with any methods or relationships that the migration might rely upon. Think of it as storing a snapshot of the required model information. This way it is okay for your models to evolve as the migration will use the locally defined models instead.

Two excellent articles on this topic, along with code examples, can be found [here](http://complicated-simplicity.com/2010/05/using-models-in-rails-migrations) and [here](http://blog.makandra.com/2010/03/how-to-use-models-in-your-migrations-without-killing-kittens).

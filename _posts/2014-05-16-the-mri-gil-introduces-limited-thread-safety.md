---
layout: post
title: "The MRI GIL introduces (limited) thread safety"
category: ruby
---
{% include JB/setup %}

Jesse Storimer wrote an amazing [three](http://www.jstorimer.com/blogs/workingwithcode/8085491-nobody-understands-the-gil) [part](http://www.jstorimer.com/blogs/workingwithcode/8100871-nobody-understands-the-gil-part-2-implementation) [series](http://www.rubyinside.com/does-the-gil-make-your-ruby-code-thread-safe-6051.html) about this. These are the bits that interest me.

**The problem**

Why is the `<<` operation thread safe in MRI Ruby, but not in JRuby and Rubinius?

{% gist vaneyckt/8dc3648427e45697b983 mri.rb %}

**The answer**

MRI Ruby is the only one of these three Ruby implementations that has a GIL. The GIL is written in such a way that a Ruby operation that is implemented as a C function that makes no callbacks to any Ruby methods, will always be executed atomically. The `<<` operation meets these requirements and as such does not require any synchronization.

Note that it's not a good idea to write code that relies on this as:

- the `<<` implementation could always change (e.g. part of the Hash insertion code is written in Ruby)
- you might want to port your code to a different Ruby implementation someday

So do be careful and use synchronization instead.

{% gist vaneyckt/8dc3648427e45697b983 mutex.rb %}

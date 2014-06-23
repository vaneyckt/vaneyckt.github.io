---
layout: post
title: "Java access modifiers"
category: java
---
{% include JB/setup %}

Just a quick post to help me keep track of the differences between C++ and Java access modifiers. It turns out Martin Fowler has a [really useful post](http://martinfowler.com/bliki/AccessModifier.html) about this already. In fact, it's so useful I'm pretty much just going to be copying the bits I'm interested in.

**C++**

- public: any class can access the feature
- protected: any subclass can access the feature
- private: no other class can access the feature

**Java**

- public: any class can access the feature
- protected: any class in the same package and ANY subclass (regardless of package)
- package private (default): any class in the same package can access the feature
- private: no other class can access the feature

It feels really weird to have the Java *protected* access modifier basically act as a package wide *public* though. C++'s approach just feels so much more natural, as it minimizes the number of exposed class features.

Aside from this, if a class is going to be subclassed inside the package only, you can just leave the relevant features to be *package private*. This makes it harder to visually inspect the code, as in C++ you see *protected* and you know your class is going to be subclassed; whereas in Java you need to look for both *protected* and *package private*.

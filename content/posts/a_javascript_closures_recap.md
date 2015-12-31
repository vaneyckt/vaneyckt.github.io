+++
date = "2015-09-26T17:54:23+00:00"
title = "A javascript closures recap"
type = "post"
ogtype = "article"
topics = [ "javascript" ]
+++

Javascript closures have always been one those things that I used to navigate by intuition. Recently however, upon stumbling across some code that I did not quite grok, it became clear I should try and obtain a more formal understanding. This post is mainly intended as a quick recap for my future self. It won't go into all the details about closures; instead it will focus on the bits that I found most helpful.

There seem to be very few step-by-step overviews of javascript closures. As a matter of fact, I only found two. Luckily they are both absolute gems. You can find them [here](http://openhome.cc/eGossip/JavaScript/Closures.html) and [here](https://web.archive.org/web/20080209105120/http://blog.morrisjohns.com/javascript_closures_for_dummies). I heartily recommend both these articles to anyone wanting to gain a more complete understanding of closures.

### Closure basics

I'm going to shamelessly borrow a few lines from the [first](http://openhome.cc/eGossip/JavaScript/Closures.html) of the two articles linked above to illustrate the basic concept of a closure.

```javascript
function doSome() {
  var x = 10;

  function f(y) {
    return x + y;
  }
  return f;
}

var foo = doSome();
foo(20); // returns 30
foo(30); // returns 40
```

> In the above example, the function f creates a closure. If you just look at f, it seems that the variable x is not defined. Actually, x is caught from the enclosing function. A closure is a function which closes (or survives) variables of the enclosing function. In the above example, the function f creates a closure because it closes the variable x into the scope of itself. If the closure object, a Function instance, is still alive, the closed variable x keeps alive. It's like that the scope of the variable x is extended.

This is really all you need to know about closures: they refer to variables declared outside the scope of the function and by doing so keep these variables alive. Closure behavior can be entirely explained just by keeping these two things in mind.

### Closures and primitive data types

The rest of this post will go over some code examples to illustrate the behavior of closures for both primitive and object params. In this section, we'll have a look at the behavior of a closure with a primitive data type param.

#### Example 1

The code below will be our starting point for studying closures. Be sure to take a good look at it, as all our examples will be a variation of this code. Throughout this post, we are going to try and understand closures by examining the values returned by the `foo()` function.

```javascript
var prim = 1;

var foo = function(p) {
  var f = function() {
    return p;
  }
  return f;
}(prim);

foo();    // returns 1
prim = 3;
foo();    // returns 1
```

When the javascript runtime wants to resolve the value returned by `return p;`, it finds that this p variable is the same as the p variable from `var foo = function(p) {`. In other words, there is no direct link between the p from `return p;` and the variable prim from `var prim = 1;`. We see this is true because assigning a new value to prim does not cause the value returned by `foo()` to change.

#### Example 2

Now let's have a look at what happens when we make a small change to the previous code sample by adding the line `p = 2;` to it.

```javascript
var prim = 1;

var foo = function(p) {
  var f = function() {
    return p;
  }
  p = 2;
  return f;
}(prim);

foo();    // returns 2
prim = 3;
foo();    // returns 2
```

The code above is interesting in that it shows that the p variable from `return p;` is indeed the same as the p variable from `var foo = function(p) {`. Even though the variable f gets created at a time when p is set to 1, the act of setting p to 2 does indeed cause the value returned by `foo()` to change. This is a great example of a closure keeping a closed variable alive.

#### Example 3

This sample shows code similar to the first, but this time we made the closure close over the prim variable.

```javascript
var prim = 1;

var foo = function() {
  return prim;
}

foo();    // returns 1
prim = 3;
foo();    // returns 3
```

Here too we can make a similar deduction as we did for the previous samples. When the javascript runtime wants to resolve the value returned by `return prim;`, it finds that this prim variable is the same as the prim variable from `var prim = 1;`. This explains why setting prim to 3 causes the value returned by `foo()` to change.

### Closures and objects

In this section we'll see what happens when we take our code samples and change the param from a primitive data type to an object.

#### Example 1.a

The code below is interesting because in the previous section we saw that a similar example using a primitive param had both calls to `foo()` return the same value. So what's different here? Let's inspect how the runtime resolves the variables involved.

```javascript
var obj = ["a"];

var foo = function(o) {
  var f = function() {
    return o.length;
  }
  return f;
}(obj);

foo();        // returns 1
obj[1] = "b"; // modifies the object pointed to by the obj var
obj[2] = "c"; // modifies the object pointed to by the obj var
foo();        // returns 3
```

When the runtime tries to resolve the variable o from `return o.length;`, it finds that this variable o is the same as the variable o from `var foo = function(o) {`. We saw this exact same thing in the previous section. Unlike the previous section, the variable o now contains a reference to an array object. This causes our closure to have a direct link to this array object, and thus any changes to it will get reflected in the output of `foo()`. This explains why the second call to `foo()` gives a different output than the first.

**A good rule of thumb goes like this:**

* **if a closed variable contains a value, then the closure links to that variable**
* **if a closed variable contains a reference to an object, then the closure links to that object, and will pick up on any changes made to it**

#### Example 1.b

Note that the closure will only pick up on changes made to the particular object that was present when the closure was created. Assigning a new object to the obj variable after the closure was created will have no effect. The code below illustrates this.

```javascript
var obj = ["a"];

var foo = function(o) {
  var f = function() {
    return o.length;
  }
  return f;
}(obj);

foo();                 // returns 1
obj = ["a", "b", "c"]; // assign a new array object to the obj variable
foo();                 // returns 1
```

In fact, this code is practically identical to the code from Example 1 of the previous section.

#### Example 2

We'll now modify the previous code sample a bit. This time we'll take a look at what happens when we add the line `o[1] = "b";`.

```javascript
var obj = ["a"];

var foo = function(o) {
  var f = function() {
    return o.length;
  }
  o[1] = "b";
  return f;
}(obj);

foo();        // returns 2
obj[1] = "b";
obj[2] = "c";
foo();        // returns 3
```

Once again, we can start by reasoning about how the runtime resolves the variable o from `return o.length;`. As you probably know by now, this variable o is the same as the variable o from `var foo = function(o) {`. And since it contains a reference to an object, any changes to this object will get reflected in the output of `foo()`. This explains why the first call to `foo()` now returns 2, whereas previously it was returning 1.

#### Example 3

If you managed to make it this far, this last bit of code should hold no surprises for you.

```javascript
var obj = ["a"];

var foo = function() {
  return obj.length;
}

foo();        // returns 1
obj[1] = "b";
obj[2] = "c";
foo();        // returns 3
```

The runtime will resolve the variable obj from `return obj.length;` to be the same as the variable obj from `var obj = ["a"];`. As a result, any changes to the obj variable will have an effect on the output of `foo()`.

### Conclusion

Hopefully this post has demystified closures a bit. Time and time again, we've shown how following a few simple steps will lead you to understand their behavior. Just keep in mind these rules of thumb and you should be good to go:

* if a closed variable contains a value, then the closure links to that variable
* if a closed variable contains a reference to an object, then the closure links to that object, and will pick up on any changes made to it

Ideally, this is going to become my go-to post for providing an introduction to closures. So please let me know any suggestions you might have to improve this post.

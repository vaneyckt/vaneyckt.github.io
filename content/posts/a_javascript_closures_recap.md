+++
date = "2015-09-26T17:54:23+00:00"
title = "A javascript closures recap"
type = "post"
ogtype = "article"
topics = [ "javascript" ]
+++

Javascript closures have always been one those things that I used to navigate by intuition. Recently however, upon stumbling across some code that I did not quite grok, it became clear I should try and obtain a more formal understanding. This post is mainly intended as a quick recap for my future self. It won't go into all the details about closures; instead it will focus on the bits that I found most helpful.

There seem to be very few step-by-step overviews of all things related to javascript closures. As a matter of fact, I only found two. Luckily they are both absolute gems. You can find them [here](http://openhome.cc/eGossip/JavaScript/Closures.html) and [here](https://web.archive.org/web/20080209105120/http://blog.morrisjohns.com/javascript_closures_for_dummies). I heartily recommend reading both these articles to anyone wanting to gain a more complete understanding of closures.

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

The rest of this post will go over some code examples to illustrate the behavior of closures for both primitive and object params. In this section we'll have a look at the behavior of a closure with a primitive data type param.

#### Example 1

This code here will be our starting point for studying closures. Be sure to take a good look at it, as all our examples will be a variation of this code. We will try to understand closures by keeping an eye on the values returned by the `foo()` function.

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

When the javascript runtime wants to resolve the value returned by `return p;`, it finds that this p variable is the same as the p variable from `var foo = function(p) {`. In other words, there is no direct link between the p from `return p;` and the variable prim from `var prim = 1;`. We see this is true because assigning a new value to prim does not cause the value returned by `foo();` to change.

#### Example 2

Let's now have a look at what happens when we make a small change to the previous code sample by adding the line `p = 2;`.

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

The code above is interesting in that it shows that the p variable from `return p;` is indeed the same as the p variable from `var foo = function(p) {`. Even though the variable f gets created at a time when p is set to 1, the act of setting p to 2 does indeed cause the value returned by `foo();` to change. This is a great example of a closure keeping a closed variable alive.

#### Example 3

The last sample below shows code similar to the first sample, but this time we made the closure close over the prim variable.

```javascript
var prim = 1;

var foo = function() {
  return prim;
}

foo();    // returns 1
prim = 3;
foo();    // returns 3
```

Here too we can make a similar deduction as we did for the previous samples. When the javascript runtime wants to resolve the value returned by `return prim;`, it finds that this prim variable is the same as the prim variable from `var prim = 1;`. This explains why setting prim to 3 causes the value returned by `foo();` to change.

### Closures and objects

In this section we'll see what happens when we take the code we looked at earlier and change the param from a primitive data type to an object.

#### Example 1.a

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

The above code is interesting because in the previous section we saw that a similar example using a primitive param had both calls to `foo()` return the same value. So what's different here? Let's do what we usually do and go over how the runtime resolves the variables involved.

When the runtime tries to resolve the variable o from `return o.length;`, it finds that this variable o is the same as the variable o from `var foo = function(o) {`. We saw this exact same thing in the previous section. Unlike the previous section however, the variable o now contains a reference to an array object. This causes our closure to have a direct link to this underlying array object. Any changes to it will get reflected in the output of `foo()`. This explains why the second call to `foo()` gives a different output than the first.

**A good rule of thumb goes like this:**

* **if a closed variable contains a value, then the closure binds to that variable**
* **if a closed variable contains a reference to an object, then the closure binds to that object, and will pick up on any changes made to it**

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

#### Example 2

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

#### Example 3

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






Unsurprisingly we get the exact same behavior as we did with primitive data types. Let's move on to the last section where we will contrast the behavior of assigning a new object to the object var with the behavior of modifying the object assigned to the object var.


gets passed the variable p as a param and then returns something (another function) that makes use of this variable p. Therefore the variable p is not outside the scope of the function, and thus the function isn't a closure.
Our next example shows similar code

Because the function isn't a closure, it has its own internal copy of p. This means that modifying the value of the primitive variable has no effect on the value returned by the function.

The function would not have its own copy of i because i is not declared within the scope of the function. It is this what is causing closures in the first place!! So there should be no closure if the variable is passed as a param to your function.

- only time we see the no closure approach output different values. The o variable is a reference to the original object variable (mention this in prev examples as well). This here is the only time we modify the previously passed reference, instead of pointing the variable to a new refrence.
- closure behaves similiarly. Since the var is not defined in the function scope, it will resolve to the outside var, which is just a reference to an array.

no closure - before assigning new value - value: 3
(index):54 no closure - after assigning new value - value: 3
(index):61 closure - before assigning new value - value: 3
(index):63 closure - after assigning new value - value: 5
(index):72 no closure - before assigning new object - value: 2
(index):74 no closure - after assigning new object - value: 2
(index):81 closure - before assigning new object - value: 2
(index):83 closure - after assigning new object - value: 3
(index):92 no closure - before modifying object - value: 2
(index):94 no closure - after modifying object - value: 3
(index):101 closure - before modifying object - value: 2
(index):103 closure - after modifying object - value: 3

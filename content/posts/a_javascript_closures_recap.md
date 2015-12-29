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

### Behavior of primitive data types

The rest of this post will go over some code examples to illustrate the behavior of closures and non-closures for both primitive and object params. In this section we'll have a look at the behavior of a function with a primitive data type param.

```javascript
// no closure
var primitive = 1;

var foo = function(p) {
  return function() {
    return p;
  }
}(primitive);

foo();         // returns 1
primitive = 2;
foo();         // returns 1
```

In the above code, the value that gets returned is the value of the variable that gets passed to the function as a param. Or to put it somewhat differently, when the javascript runtime wants to resolve the value returned by `return p`, it finds that this p variable is the same as the p variable from `var foo = function(p)`. Or in other words, there is no direct link between the p from `return p` and the primitive variable from `var primitive = 3`. We see that this is true because assigning a new value to the primitive variable does not cause the value returned by `foo()` to change.

The sample below shows similar code, but this time using closures. How do we know it's a closure? Well, it's easy. Remember that a closure is a function that refers to variables declared outside its scope. Here we have a function that refers to a primitive variable that was not declared inside the scope of this function. This is the very definition of a closure!

```javascript
// closure
var primitive = 1;

var foo = function() {
  return primitive;
}

foo();         // returns 1
primitive = 2;
foo();         // returns 2
```

Here too we can make a similar deduction as we did for the previous code sample. When the javascript runtime wants to resolve the value returned by `return primitive`, it finds that the primitive variable is the same as the primitive variable from `var primitive = 3`. This explains why modifying the primitive variable changes the value returned by `foo()`.

### Behavior of objects (when assigning)

In this section we'll see what happens when we take the code we looked at earlier and change the param from a primitive data type to an object. Spoiler warning: they behave in exactly the same way. The real reason this section is here is so we can refer back to it in the next section where we will have a look at the effect of modifying object params.

```javascript
// no closure
var object = ["a", "b"];

var foo = function(o) {
  return function() {
    return o.length;
  }
}(object);

foo();                    // returns 2
object = ["a", "b", "c"]; // assigning new object to object var
foo();                    // returns 2
```

```javascript
// closure
var object = ["a", "b"];

var foo = function() {
  return object.length;
}

foo();                    // returns 2
object = ["a", "b", "c"]; // assigning new object to object var
foo();                    // returns 3
```

Unsurprisingly we get the exact same behavior as we did with primitive data types. Let's move on to the last section where we will contrast the behavior of assigning a new object to the object var with the behavior of modifying the object assigned to the object var.

### Behavior of objects (when modifying)

```javascript
// no closure
var object = ["a", "b"];

var foo = function(o) {
  return function() {
    return o.length;
  }
}(object);

foo();           // returns 2
object[2] = "c"; // modifying object assigned to object var
foo();           // returns 3
```

```javascript
// closure
var object = ["a", "b"];

var foo = function() {
  return object.length;
}

foo();           // returns 2
object[2] = "c"; // modifying object assigned to object var
foo();           // returns 3
```

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

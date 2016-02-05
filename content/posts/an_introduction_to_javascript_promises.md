+++
date = "2015-02-07T18:34:09+00:00"
title = "An introduction to javascript promises"
type = "post"
ogtype = "article"
topics = [ "javascript" ]
+++

I recently had to write some javascript code that required the sequential execution of half a dozen asynchronous requests. I figured this was the perfect time to learn a bit more about javascript promises. This post is a recap of what I read in these [three](http://www.html5rocks.com/en/tutorials/es6/promises/) [amazing](http://www.mullie.eu/how-javascript-promises-work/) [write-ups](http://www.sitepoint.com/overview-javascript-promises/).

### What are promises?
A Promise object represents a value that may not be available yet, but will be resolved at some point in future. This abstraction allows you to write asynchronous code in a more synchronous fashion. For example, you can use a Promise object to represent data that will eventually be returned by a call to a remote web service. The `then` and `catch` methods can be used to attach callbacks that will be triggered once the data arrives. We'll take a closer look at these two methods in the next sections. For now, let's write a simple AJAX request example that prints a random joke.

```javascript
var promise = new Promise(function(resolve, reject) {
  $.ajax({
    url: "http://api.icndb.com/jokes/random",
    success: function(result) {
      resolve(result["value"]["joke"]);
    }
  });
});

promise.then(function(result) {
  console.log(result);
});
```

Note how the Promise object is just a wrapper around the AJAX request and how we've instructed the `success` callback to trigger the `resolve` method. We've also attached a callback to our Promise object with the `then` method. This callback gets triggered when the `resolve` method gets called. The `result` variable of this callback will contain the data that was passed to the `resolve` method.

Before we take a closer look at the `resolve` method, let's first investigate the Promise object a bit more. A Promise object can have one of three states:

- **fulfilled** - the action relating to the Promise succeeded
- **rejected** - the action relating to the Promise failed
- **pending** - the Promise hasn't been fulfilled or rejected yet

A pending Promise object can be fulfilled or rejected by calling `resolve` or `reject` on it. Once a Promise is fulfilled or rejected, this state gets permanently associated with it. The state of a fulfilled Promise also includes the data that was passed to `resolve`, just as the state of a rejected Promise also includes the data that was passed to `reject`. In summary, we can say that a Promise executes only once and stores the result of its execution.

```javascript
var promise = new Promise(function(resolve, reject) {
  $.ajax({
    url: "http://api.icndb.com/jokes/random",
    success: function(result) {
      resolve(result["value"]["joke"]);
    }
  });
});

promise.then(function(result) {
  console.log(result);
});

promise.then(function(result) {
  console.log(result);
});
```

We can test whether a Promise only ever executes once by adding a second callback to the previous example. In this case, we see that only one AJAX request gets made and that the same joke gets printed to the console twice. This clearly shows that our Promise was only executed once.

### The `then` method and chaining
The `then` method takes two arguments: a mandatory success callback and an optional failure callback. These callbacks are called when the Promise is settled (i.e. either fulfilled or rejected). If the Promise was fulfilled, the success callback will be fired with the data you passed to `resolve`. If the Promise was rejected, the failure callback will be called with the data you passed to `reject`. We've already covered most of this in the previous section.

The real magic with the `then` method happens when you start chaining several of them together. This chaining allows you to express your logic in separate stages, each of which can be made responsible for transforming data passed on by the previous stage or for running additional asynchronous requests. The code below shows how data returned by the success callback of the first `then` method becomes available to the success callback of the second `then` method.

```javascript
var promise = new Promise(function(resolve, reject) {
  $.ajax({
    url: "http://api.icndb.com/jokes/random",
    success: function(result) {
      resolve(result["value"]["joke"]);
    }
  });
});

promise.then(function(result) {
  return result;
}).then(function(result) {
  console.log(result);
});
```

This chaining is possible because the `then` method returns a new Promise object that will resolve to the return value of the callback. Or in other words, by calling `return result;` we cause the creation of an anonymous Promise object that looks something like shown below. Notice that this particular anonymous Promise object will resolve immediately, as it does not make any asynchronous requests.

```javascript
new Promise(function(resolve, reject) {
  resolve(result);
});
```

Now that we understand that the `then` method always returns a Promise object, let's take a look at what happens when we tell the callback of a `then` method to explicitly return a Promise object.

```javascript
function getJokePromise() {
  return new Promise(function(resolve, reject) {
    $.ajax({
      url: "http://api.icndb.com/jokes/random",
      success: function(result) {
        resolve(result["value"]["joke"]);
      }
    });
  });
}

getJokePromise().then(function(result) {
  console.log(result);
  return getJokePromise();
}).then(function(result) {
  console.log(result);
});
```

In this case, we end up sequentially executing two asynchronous requests. When the first Promise is resolved, the first joke is printed and a new Promise object is returned by the `then` method. This new Promise object then has `then` called on it. When the Promise succeeds, the `then` success callback is triggered and the second joke is printed.

The takeaway from all this is that calling `return` in a `then` callback will always result in returning a Promise object. It is this that allows for `then` chaining!

### Error handling
We mentioned in the previous section how the `then` method can take an optional failure callback that gets triggered when `reject` is called. It is customary to reject with an Error object as they capture a stack trace, thereby facilitating debugging.

```javascript
var promise = new Promise(function(resolve, reject) {
  $.ajax({
    url: "http://random.url.com",
    success: function(result) {
      resolve(result["value"]["joke"]);
    },
    error: function(jqxhr, textStatus) {
      reject(Error("The AJAX request failed."));
    }
  });
});

promise.then(function(result) {
  console.log(result);
}, function(error) {
  console.log(error);
  console.log(error.stack);
});
```

Personally, I find this a bit hard to read. Luckily we can use the `catch` method to make this look a bit nicer. There's nothing special about the `catch` method. In fact, it's just sugar for `then(undefined, func)`, but it definitely makes code easier to read.

```javascript
var promise = new Promise(function(resolve, reject) {
  $.ajax({
    url: "http://random.url.com",
    success: function(result) {
      resolve(result["value"]["joke"]);
    },
    error: function(jqxhr, textStatus) {
      reject(Error("The AJAX request failed."));
    }
  });
});

promise.then(function(result) {
  console.log(result);
}).then(function(result) {
  console.log("foo"); // gets skipped
}).then(function(result) {
  console.log("bar"); // gets skipped
}).catch(function(error) {
  console.log(error);
  console.log(error.stack);
});
```

Aside from illustrating improved readability, the above code showcases another aspect of the `reject` method in that Promise rejections will cause your code to skip forward to the next `then` method that has a rejection callback (or the next `catch` method, since this is equivalent). It is this fallthrough behavior that causes this code to not print "foo" or "bar"!

As a final point, it is useful to know that a Promise is implicitly rejected if an error is thrown in its constructor callback. This means it's useful to do all your Promise related work inside the Promise constructor callback, so errors automatically become rejections.

```javascript
var promise = new Promise(function(resolve, reject) {
  // JSON.parse throws an error if you feed it some
  // invalid JSON, so this implicitly rejects
  JSON.parse("This ain't JSON");
});

promise.then(function(result) {
  console.log(result);
}).catch(function(error) {
  console.log(error);
});
```

The above code will cause the Promise to be rejected and an error to be printed because it will fail to parse the invalid JSON string.

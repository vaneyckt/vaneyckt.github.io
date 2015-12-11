+++
date = "2013-11-10T20:50:04+00:00"
title = "The javascript event loop"
type = "post"
ogtype = "article"
tags = [ "javascript" ]
+++

Sometimes you come across an article that is so well written you can't do anything but link to it. So if you've ever wondered why the javascript runtime is so good at asynchronous operations, then you should definitely give [this article](http://blog.carbonfive.com/2013/10/27/the-javascript-event-loop-explained/) a read.

Some snippets:

> JavaScript runtimes contain a message queue which stores a list of messages to be processed and their associated callback functions. These messages are queued in response to external events (such as a mouse being clicked or receiving the response to an HTTP request) given a callback function has been provided. If, for example a user were to click a button and no callback function was provided – no message would have been enqueued.

> In a loop, the queue is polled for the next message (each poll referred to as a “tick”) and when a message is encountered, the callback for that message is executed.

> The calling of this callback function serves as the initial frame in the call stack, and due to JavaScript being single-threaded, further message polling and processing is halted pending the return of all calls on the stack.

As well as:

> Using Web Workers enables you to offload an expensive operation to a separate thread of execution, freeing up the main thread to do other things. The worker includes a separate message queue, event loop, and memory space independent from the original thread that instantiated it. Communication between the worker and the main thread is done via message passing, which looks very much like the traditional, evented code-examples we’ve already seen.

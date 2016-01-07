+++
date = "2013-10-09T16:09:32+00:00"
title = "GET vs POST"
type = "post"
ogtype = "article"
topics = [ "general" ]
+++

Today I was looking into why a particular GET request was failing on IE. As it turned out this was due to IE not appreciating long query strings. While going through our nginx logs, we also found nginx had a default query string limit that was being hit sporadically by some other customers as well. The solution in both cases was to move the affected calls from GET to POST.

The above problem prompted me to take a closer look at the differences between GET and POST requests. You probably use these all the time, but do you know how each of them functions?

#### GET requests

- can be bookmarked
- can be cached for faster response time on subsequent request
- request is stored in browser history
- uses query strings to send data. There is a limit to the allowable length of a query string.
- have their url and query strings stored in plaintext in server logs. This is why you should never send passwords over GET requests!
- use these for actions that retrieve data. For example, you don't want to use GET requests for posting comments on your blog. Otherwise an attacker could copy a url that posts a specific comment and put it on twitter. Every time someone were to click this link, a comment would now be posted on your blog.

#### POST requests

- cannot be bookmarked
- cannot be cached
- request will not be stored in browser history
- uses POST body to send data. There is no limit to the amount of data sent due to the multipart content-type spreading your data across multiple messages when necessary.
- have their url stored in plaintext in server logs. The data itself will not be logged though.
- use these for actions that alter data

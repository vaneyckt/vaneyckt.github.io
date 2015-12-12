+++
date = "2013-10-08T13:24:17+00:00"
title = "The dig command"
type = "post"
ogtype = "article"
topics = [ "linux" ]
+++

Today I learned of the existence of the [dig command](http://linux.die.net/man/1/dig). A very useful little tool for DNS lookups. Here's an example of it in action.

```bash
$ dig www.google.com

; <<>> DiG 9.8.3-P1 <<>> www.google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 4868
;; flags: qr rd ra; QUERY: 1, ANSWER: 6, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;www.google.com.			IN	A

;; ANSWER SECTION:
www.google.com.		72	IN	A	74.125.24.105
www.google.com.		72	IN	A	74.125.24.103
www.google.com.		72	IN	A	74.125.24.104
www.google.com.		72	IN	A	74.125.24.99
www.google.com.		72	IN	A	74.125.24.147
www.google.com.		72	IN	A	74.125.24.106

;; Query time: 11 msec
;; SERVER: 192.168.0.1#53(192.168.0.1)
;; WHEN: Sat Aug 29 13:38:48 2015
;; MSG SIZE  rcvd: 128
```

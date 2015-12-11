+++
date = "2013-10-21T17:21:52+00:00"
title = "Get connection information with the lsof command"
type = "post"
ogtype = "article"
tags = [ "linux" ]
+++

The [lsof command](http://linux.die.net/man/8/lsof) is one of those super useful commands for figuring out what connections are taking place on your machine. While the `lsof` command technically just **l**i**s**ts **o**pen **f**iles, just about everything in linux (even sockets) is a file!

Some useful commands:

####List all network connections
```bash
$ lsof -i

COMMAND     PID     USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
Spotify   36908 vaneyckt   53u  IPv4 0x2097c8deb175c0dd      0t0  TCP localhost:4381 (LISTEN)
Spotify   36908 vaneyckt   54u  IPv4 0x2097c8deab18027d      0t0  TCP localhost:4371 (LISTEN)
Spotify   36908 vaneyckt   71u  IPv4 0x2097c8deba747c1d      0t0  UDP *:57621
Spotify   36908 vaneyckt   72u  IPv4 0x2097c8deb18ef4cd      0t0  TCP *:57621 (LISTEN)
Spotify   36908 vaneyckt   77u  IPv4 0x2097c8deb993b255      0t0  UDP ip-192-168-0-101.ec2.internal:61009
Spotify   36908 vaneyckt   90u  IPv4 0x2097c8dea8c4a66d      0t0  TCP ip-192-168-0-101.ec2.internal:62432->lon3-accesspoint-a57.lon3.spotify.com:https (ESTABLISHED)
Spotify   36908 vaneyckt   91u  IPv4 0x2097c8de8d029f2d      0t0  UDP ip-192-168-0-101.ec2.internal:52706
```

####List all network connections on port 4381
```bash
$ lsof -i :4381

COMMAND   PID     USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
Spotify 36908 vaneyckt   53u  IPv4 0x2097c8deb175c0dd      0t0  TCP localhost:4381 (LISTEN)
```

####Find ports listening for connections
```bash
$ lsof -i | grep -i LISTEN

Spotify   36908 vaneyckt   53u  IPv4 0x2097c8deb175c0dd      0t0  TCP localhost:4381 (LISTEN)
Spotify   36908 vaneyckt   54u  IPv4 0x2097c8deab18027d      0t0  TCP localhost:4371 (LISTEN)
Spotify   36908 vaneyckt   72u  IPv4 0x2097c8deb18ef4cd      0t0  TCP *:57621 (LISTEN)
```

####Find established connections
```bash
$ lsof -i | grep -i ESTABLISHED

Spotify   36908 vaneyckt   90u  IPv4 0x2097c8dea8c4a66d      0t0  TCP ip-192-168-0-101.ec2.internal:62432->lon3-accesspoint-a57.lon3.spotify.com:https (ESTABLISHED)
```

####Show all files opened by a given process
```bash
$ lsof -p 36908

COMMAND   PID     USER   FD     TYPE             DEVICE  SIZE/OFF     NODE NAME
Spotify 36908 vaneyckt   90u    IPv4 0x2097c8dea8c4a66d       0t0      TCP ip-192-168-0-101.ec2.internal:62432->lon3-accesspoint-a57.lon3.spotify.com:https (ESTABLISHED)
Spotify 36908 vaneyckt   91u    IPv4 0x2097c8de8d029f2d       0t0      UDP ip-192-168-0-101.ec2.internal:52706
Spotify 36908 vaneyckt   92u     REG                1,4   9389456 59387889 /Users/vaneyckt/Library/Caches/com.spotify.client/Data/4a/4a5a23cf1e9dc4210b3c801d57a899098dc12418.file
Spotify 36908 vaneyckt   93u     REG                1,4   8658944 58471210 /private/var/folders/xv/fjmwzr9x5mq_s7dchjq87hjm0000gn/T/.org.chromium.Chromium.6b0Vzp
Spotify 36908 vaneyckt   94u     REG                1,4    524656 54784499 /Users/vaneyckt/Library/Caches/com.spotify.client/Browser/index
Spotify 36908 vaneyckt   95u     REG                1,4     81920 54784500 /Users/vaneyckt/Library/Caches/com.spotify.client/Browser/data_0
Spotify 36908 vaneyckt   96u     REG                1,4    532480 54784501 /Users/vaneyckt/Library/Caches/com.spotify.client/Browser/data_1
Spotify 36908 vaneyckt   97u     REG                1,4   2105344 54784502 /Users/vaneyckt/Library/Caches/com.spotify.client/Browser/data_2
Spotify 36908 vaneyckt   98u     REG                1,4  12591104 54784503 /Users/vaneyckt/Library/Caches/com.spotify.client/Browser/data_3
Spotify 36908 vaneyckt   99r     REG                1,4    144580    28952 /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Resources/HIToolbox.rsrc
```

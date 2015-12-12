+++
date = "2014-03-04T20:40:56+00:00"
title = "Programmatically creating Android touch events"
type = "post"
ogtype = "article"
topics = [ "android" ]
+++

Recent versions of Android have the `adb shell input touch` functionality to simulate touch events on an Android device or simulator. However, older Android versions (like 2.3) do not support this command. Luckily it is possible to recreate this functionality by running `adb shell getevent` to capture events as they are being generated. These events can then later be replayed using the `adb shell sendevent` command.

Running `adb shell getevent` when touching the screen might get you something like shown below. Notice how the output is in hexadecimal.

```bash
/dev/input/event7: 0001 014a 00000001
/dev/input/event7: 0003 003a 00000001
/dev/input/event7: 0003 0035 000001ce
/dev/input/event7: 0003 0036 00000382
/dev/input/event7: 0000 0002 00000000
/dev/input/event7: 0000 0000 00000000
/dev/input/event7: 0001 014a 00000000
/dev/input/event7: 0003 003a 00000000
/dev/input/event7: 0003 0035 000001ce
/dev/input/event7: 0003 0036 00000382
/dev/input/event7: 0000 0002 00000000
/dev/input/event7: 0000 0000 00000000
```

However, the `adb shell sendevent` command expect all of its input to be in decimal. So if we wanted to replay the above events, we'd need to do something like shown below. Note that 462 and 898 are the x and y coordinates of this particular touch event.

```bash
adb shell sendevent /dev/input/event7: 1 330 1
adb shell sendevent /dev/input/event7: 3 58 1
adb shell sendevent /dev/input/event7: 3 53 462
adb shell sendevent /dev/input/event7: 3 54 898
adb shell sendevent /dev/input/event7: 0 2 0
adb shell sendevent /dev/input/event7: 0 0 0
adb shell sendevent /dev/input/event7: 1 330 0
adb shell sendevent /dev/input/event7: 3 58 0
adb shell sendevent /dev/input/event7: 3 53 462
adb shell sendevent /dev/input/event7: 3 54 898
adb shell sendevent /dev/input/event7: 0 2 0
adb shell sendevent /dev/input/event7: 0 0 0
```

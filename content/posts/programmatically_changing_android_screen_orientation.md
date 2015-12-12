+++
date = "2014-03-20T20:08:17+00:00"
title = "Programmatically changing Android screen orientation"
type = "post"
ogtype = "article"
topics = [ "android" ]
+++

A lot of digital ink has been spilled on this subject, so I figured it might be worth to briefly talk about this. You can either change the orientation through ADB or through an app. While the ADB approach is the easiest, it might not work on all devices or on all Android versions. For example, the `dumpsys` output of a Kindle Fire is different than that of a Samsung Galaxy S4, so you might need to tweak the grepping of the output.

```bash
# get current orientation
adb shell dumpsys input | grep SurfaceOrientation | awk '{print $2}'

# change orientaton to portait
adb shell content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0
adb shell content insert --uri content://settings/system --bind name:s:user_rotation --bind value:i:0

# change orientation to landscape
adb shell content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0
adb shell content insert --uri content://settings/system --bind name:s:user_rotation --bind value:i:1
```

If you don’t want to use ADB and prefer to change the orientation through an Android app instead, then you can just use these commands.

```java
// get current orientation
final int orientation = myActivity.getResources().getConfiguration().orientation;

// change orientation to portrait
myActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);

// change orientation to landscape
myActivity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
```

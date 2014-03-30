---
layout: post
title: "Checking which Java version a JAR was compiled for"
category: java
---
{% include JB/setup %}

We recently upgraded from Java 6 to Java 7 and wanted to double-check that our build process was now indeed creating JARs targeted at Java 7. Luckily it is rather straightforward to do so. Just run `jar xf <my_jar.jar>` to extract the files, followed by `file <my_file.class>` to determine the byte code class version of a given file. The class version maps to the JDK version as shown below.

{% gist vaneyckt/df2bba98ca753b8a53cb %}

---
layout: post
title: "Programmatically setting the selected item in an Android spinner"
category: android
---
{% include JB/setup %}

I recently needed to programmatically set the selected item in a dropdown (spinner) in an Android app. Depending on how you're populating the spinner and on what information you have available, you'll probably end up going with one of three approaches. Note that this code was taken from [this StackOverflow thread](http://stackoverflow.com/questions/11072576/set-selected-item-of-spinner-programmatically).

a) if you know the index of the item you want selected

`mySpinner.setSelection(INDEX_OF_ITEM);`

b) if you know the displayed name of the item you want selected and you're using an adapter to populate the spinner

`mySpinner.setSelection(arrayAdapter.getPosition("Item Name"));`

c) if you know the displayed name, but aren't using an adapter

`mySpinner.setSelection(((ArrayAdapter)mySpinner.getAdapter()).getPosition("Item Name‌​"));`

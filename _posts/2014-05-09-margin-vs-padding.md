---
layout: post
title: "Margin vs padding"
category: css
---
{% include JB/setup %}

StackOverflow has the best [concise explanations](http://stackoverflow.com/questions/2189452/when-to-use-margin-vs-padding-in-css):

- margin is on the outside of block elements while padding is on the inside
- use margin to separate the block from things outside it
- use padding to move the contents away from the edges of the block
- favor using margin, except when you have a border or background and want to increase the space inside that visible box

However, these explanations overlook [margin collapsing](http://www.sitepoint.com/web-foundations/collapsing-margins):

- when the vertical margins of two elements are touching, only the margin of the element with the largest margin value will be honored
- if one element has a negative margin, the margin values are added together to determine the final value
- if both are negative, the greater negative value is used

Note that margin collapsing only occurs for vertical margins.

{% gist vaneyckt/3cc1ad7c647917bd9146 vertical.html %}

{% gist vaneyckt/3cc1ad7c647917bd9146 horizontal.html %}

There are some exceptions to this as well. Margin collapsing does not occur for the following elements:

- floated elements
- absolutely positioned elements
- inline-block elements
- elements with overflow set to anything other than visible do not collapse margins with their children
- cleared elements do not collapse their top margins with their parent block’s bottom margin
- the root element

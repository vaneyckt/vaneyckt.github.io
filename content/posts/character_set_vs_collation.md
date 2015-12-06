+++
date = "2013-10-19T20:31:43+00:00"
title = "Character set vs collation"
type = "post"
ogtype = "article"
tags = [ "mysql" ]
+++

There's a surprising amount of confusion about the difference between these two terms. The best explanation I've found is [here](http://stackoverflow.com/questions/341273/what-does-character-set-and-collation-mean-exactly/341481#341481).

>A character set is a subset of all written glyphs. A character encoding specifies how those characters are mapped to numeric values. Some character encodings, like UTF-8 and UTF-16, can encode any character in the Universal Character Set. Others, like US-ASCII or ISO-8859-1 can only encode a small subset, since they use 7 and 8 bits per character, respectively. Because many standards specify both a character set and a character encoding, the term "character set" is often substituted freely for "character encoding".

>A collation comprises rules that specify how characters can be compared for sorting. Collations rules can be locale-specific: the proper order of two characters varies from language to language.

>Choosing a character set and collation comes down to whether your application is internationalized or not. If not, what locale are you targeting?

>In order to choose what character set you want to support, you have to consider your application. If you are storing user-supplied input, it might be hard to foresee all the locales in which your software will eventually be used. To support them all, it might be best to support the UCS (Unicode) from the start. However, there is a cost to this; many western European characters will now require two bytes of storage per character instead of one.

>Choosing the right collation can help performance if your database uses the collation to create an index, and later uses that index to provide sorted results. However, since collation rules are often locale-specific, that index will be worthless if you need to sort results according to the rules of another locale.

The only thing I'd like to add is that some collations are more cpu intensive than others. For example, `utf8_general_ci` treats À, Á, and Å as being equal to A when doing comparisons. This is in contrast to `utf8_unicode_ci` which uses about 10% more cpu, but differentiates between these characters.

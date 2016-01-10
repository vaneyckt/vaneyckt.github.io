set -eux

the -e makes it fail if anything returns a non-zero value
means you don't have to explicitly check for it, cleaner code

https://stackoverflow.com/questions/821396/aborting-a-shell-script-if-any-command-returns-a-non-zero-value

tom [5:49 PM]
@emil.varga: are you sure this is correct? https://github.com/Swrve/swrve/blob/release-74/batch/test_emrlib.py#L147

emil.varga [5:51 PM]
the last time I've looked it seemed ok, why?

​[5:52]
it checks that the method returns the previous value

tom [5:54 PM]
because it looks like deleting that env var, would cause the EmrLib to return /mnt/tmp(edited)

​[5:54]
https://github.com/Swrve/swrve/blob/release-74/batch/swrve/emr.py#L301

​[5:56]
@emil.varga: ^

emil.varga [5:57 PM]
ook.. yes that would have been the prev value

​[5:57]
is that breaking the CI as the ENV variable is deleted?

tom [5:58 PM]
it wasnt :simple_smile:

​[5:58]
but now it will

emil.varga [5:58 PM]
hahaha

​[5:59]
why?

tom [5:59 PM]
the script that ran those tests did not have "set -e" at the top

emil.varga [5:59 PM]
ok

tom [5:59 PM]
so the non-zero value being returned by the python test runner did not crash the test

emil.varga [5:59 PM]
was it returning non-zero values?

​[5:59]
so the tests were breaking??

tom [6:00 PM]
it was throwing an exception, but some other code ran after that. So the final exit value of the script was still 0.

​[6:00]
yes, the test was breaking

​[6:00]
but the breakage did not fail the build

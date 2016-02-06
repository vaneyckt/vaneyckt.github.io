+++
date = "2015-07-16T19:43:34+00:00"
title = "Safer bash scripts with 'set -euxo pipefail'"
type = "post"
ogtype = "article"
topics = [ "linux" ]
+++

Often times developers go about writing bash scripts the same as writing code in a higher-level language. This is a big mistake as higher-level languages offer safeguards that are not present in bash scripts by default. For example, a Ruby script will throw an error when trying to read from an uninitialized variable, whereas a bash script won't. In this article, we'll look at how we can improve on this.

The bash shell comes with several builtin commands for modifying the behavior of the shell itself. We are particularly interested in the [set builtin](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html), as this command has several options that will help us write safer scripts. I hope to convince you that it's a really good idea to add `set -euxo pipefail` to the beginning of all your future bash scripts.

### set -e

The `-e` option will cause a bash script to exit immediately when a command fails. This is generally a vast improvement upon the default behavior where the script just ignores the failing command and continues with the next line. This option is also smart enough to not react on failing commands that are part of conditional statements. Moreover, you can append a command with `|| true` for those rare cases where you don't want a failing command to trigger an immediate exit.

#### Before
```bash
#!/bin/bash

# 'foo' is a non-existing command
foo
echo "bar"

# output
# ------
# line 4: foo: command not found
# bar
```

#### After
```bash
#!/bin/bash
set -e

# 'foo' is a non-existing command
foo
echo "bar"

# output
# ------
# line 5: foo: command not found
```

#### Prevent immediate exit
```bash
#!/bin/bash
set -e

# 'foo' is a non-existing command
foo || true
echo "bar"

# output
# ------
# line 5: foo: command not found
# bar
```

### set -o pipefail

The bash shell normally only looks at the exit code of the last command of a pipeline. This behavior is not ideal as it causes the `-e` option to only be able to act on the exit code of a pipeline's last command. This is where `-o pipefail` comes in. This particular option sets the exit code of a pipeline to that of the rightmost command to exit with a non-zero status, or zero if all commands of the pipeline exit successfully.

#### Before
```bash
#!/bin/bash
set -e

# 'foo' is a non-existing command
foo | echo "a"
echo "bar"

# output
# ------
# a
# line 5: foo: command not found
# bar
```

#### After
```bash
#!/bin/bash
set -eo pipefail

# 'foo' is a non-existing command
foo | echo "a"
echo "bar"

# output
# ------
# a
# line 5: foo: command not found
```

### set -u

This option causes the bash shell to treat unset variables as an error and exit immediately. This brings us much closer to the behavior of higher-level languages.

#### Before
```bash
#!/bin/bash
set -eo pipefail

echo $a
echo "bar"

# output
# ------
#
# bar
```

#### After
```bash
#!/bin/bash
set -euo pipefail

echo $a
echo "bar"

# output
# ------
# line 5: a: unbound variable
```

### set -x

The `-x` option causes bash to print each command before executing it. This can be of great help when you have to try and debug a bash script failure through its logs. Note that arguments get expanded before a command gets printed. This causes our logs to display the actual argument values at the time of execution!

```bash
#!/bin/bash
set -euxo pipefail

a=5
echo $a
echo "bar"

# output
# ------
# + a=5
# + echo 5
# 5
# + echo bar
# bar
```

And that's it. I hope this post showed you why using `set -euxo pipefail` is such a good idea. If you have any other options you want to suggest, then please let me know and I'll be happy to add them to this list.

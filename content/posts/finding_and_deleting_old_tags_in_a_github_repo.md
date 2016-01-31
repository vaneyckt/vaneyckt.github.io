+++
date = "2014-07-18T19:32:12+00:00"
title = "Finding and deleting old tags in a Github repository"
type = "post"
ogtype = "article"
topics = [ "git" ]
+++

It's very easy for a Github repository to accumulate lots of tags over time. This onslaught of tags tends to be tolerated until it starts impacting git performance. It is at this point, when you have well in excess of tens of thousands of tags, that a call to action tends to be made. In this article, we'll look at two approaches to rid yourself of these old tags.

### The cut-off tag approach

This approach has us specify a cut-off tag. All tags that can trace their ancestry back to this cut-off tag will be allowed to remain. All others will get deleted. This is especially useful for when you have just merged a new feature, and now you want to delete all tags that were created before this merge. In this scenario, all you have to do is tag the merge commit and then use this as the cut-off tag.

The sequence of commands below deletes all tags that do not have the release-5 tag as an ancestor. Most of these commands are pretty self-explanatory, except for the one in the middle. The remainder of this section will focus on explaining this command.

```bash
# fetch all tags from the remote
git fetch

# delete all tags on the remote that do not have the release-5 tag as an ancestor
comm -23 <(git tag | sort) <(git tag --contains release-5 | sort) | xargs git push --delete origin

# delete all local tags that are no longer present on the remote
git fetch --prune origin +refs/tags/*:refs/tags/*
```

The [comm command](http://linux.die.net/man/1/comm) is used to [compare two sorted files line by line](http://www.unixcl.com/2009/08/linux-comm-command-brief-tutorial.html). Luckily, we can avoid having to create any actual files by relying on process substitution instead.

```bash
comm -23 <(command to act as file 1) <(command to act as file 2) | xargs git push --delete origin
```

The `-23` flag tells `comm` to suppress any lines that are unique to file 2, as well as any lines that appear in both files. In other words, it causes `comm` to return just those lines that only appear in file 1. Looking back at our sequence of commands above, it should be clear that this will cause us to obtain all tags that do not have the release-5 tag as an ancestor. Piping this output to `xargs git push --delete origin` will then remove these tags from Github.

### The cut-off date approach

While the cut-off tag approach works great in a lot of scenarios, sometimes you just want to delete all tags that were created before a given cut-off date instead. Unfortunately, git doesn't have any built-in functionality for accomplishing this. This is why we are going to make use of a Ruby script here.

```ruby
# CUT_OFF_DATE needs to be of YYYY-MM-DD format
CUT_OFF_DATE = "2015-05-10"

def get_old_tags(cut_off_date)  
  `git log --tags --simplify-by-decoration --pretty="format:%ai %d"`
  .split("\n")
  .each_with_object([]) do |line, old_tags|
    if line.include?("tag: ")
      date = line[0..9]
      tags = line[28..-2].gsub(",", "").concat(" ").scan(/tag: (.*?) /).flatten
      old_tags.concat(tags) if date < cut_off_date
    end
  end
end

# fetch all tags from the remote
`git fetch`

# delete all tags on the remote that were created before the CUT_OFF_DATE
get_old_tags(CUT_OFF_DATE).each_slice(100) do |batch|
  system("git", "push", "--delete", "origin", *batch)
end

# delete all local tags that are no longer present on the remote
`git fetch --prune origin +refs/tags/*:refs/tags/*`
```

This Ruby script should be pretty straightforward. The `get_old_tags` method might stand out a bit here. It can look pretty complex, but most of it is just string manipulation to get the date and tags of each line outputted by the `git log` command, and storing old tags in the `old_tags` array. Note how we invoke the `system` method with an array of arguments for those calls that require input. This protects us against possible shell injection.

Be careful, as running this exact script inside your repository will delete all tags created before 2015-05-10. Also, be sure to specify your cut-off date in YYYY-MM-DD format!

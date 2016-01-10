+++
date = "2014-02-08T18:05:12+00:00"
title = "Some lesser known Github API functionality"
type = "post"
ogtype = "article"
topics = [ "git" ]
+++

One of our automation tools occasionally needs to interact with our Github repositories. Unfortunately, the current implementation of this tool leaves something to be desired as it requires cloning these repositories to local disk. Changes against these local repositories are then made on local branches, after which these branches get pushed to Github.

However, in order to save on disk space this tool will only ever create a single local copy of each repository. This makes it unsafe to run multiple instances of this tool as multiple instances simultaneously executing sequences of git commands against the same local repositories might lead to these commands inadvertently getting interpolated, thereby leaving the local repositories in an undefined state.

The solution to this complexity was to completely remove the need for local repositories and instead aim to have everything done through the wonderful Github API. This article is a reminder to myself about some API functionality that I found while looking into this.

### Checking if a branch contains a commit

While the Github API does not have an explicit call to check whether a given commit is included in a branch, we can nevertheless use the [compare call](https://developer.github.com/v3/repos/commits/#compare-two-commits) for just this purpose. This call takes two commits as input and returns a large JSON response of comparison data. We can use the `status` field of the response to ascertain if a given commit is behind or identical to the HEAD commit of a branch. If so, then the branch contains that commit.

```ruby
require 'octokit'

class GithubClient < Octokit::Client
  def branch_contains_sha?(repo, branch, sha)
    ['behind', 'identical'].include?(compare(repo, branch, sha).status)
  end
end
```

### Creating a remote branch from a remote commit

Sometimes you'll want to create a remote branch by branching from a remote commit. We can use the [create_reference call](https://developer.github.com/v3/git/refs/#create-a-reference) to accomplish this. Note that the `ref` parameter of this call needs to be set to `refs/heads/#{branch}` when creating a remote branch.

```ruby
require 'octokit'

class GithubClient < Octokit::Client
  def create_branch_from_sha(repo, branch, sha)
    # create_ref internally transforms "heads/#{branch}" into "refs/heads/#{branch}"
    # as mentioned above, this is required by the Github API
    create_ref(repo, "heads/#{branch}", sha)
  end
end
```

### Setting the HEAD of a remote branch to a specific remote commit

You can even forcefully set the HEAD of a remote branch to a specific remote commit by using the [update_reference call](https://developer.github.com/v3/git/refs/#update-a-reference). As mentioned earlier, the `ref` parameter needs to be set to `refs/heads/#{branch}`. Be careful when using this functionality though as it essentially allows you to overwrite the history of a remote branch!

```ruby
require 'octokit'

class GithubClient < Octokit::Client
  def update_branch_to_sha(repo, branch, sha, force = true)
    # update_ref internally transforms "heads/#{branch}" into "refs/heads/#{branch}"
    # as mentioned earlier, this is required by the Github API
    update_ref(repo, "heads/#{branch}", sha, force)
  end
end
```

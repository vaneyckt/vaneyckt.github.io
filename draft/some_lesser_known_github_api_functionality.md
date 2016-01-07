+++
date = "2014-02-08T18:05:12+00:00"
title = "Some lesser known Github API functionality"
type = "post"
ogtype = "article"
topics = [ "git" ]
+++

One of the automation tools at work occasionally needs to interact with our Github repositories. Unfortunately its current implementation leaves something to be desired as it requires our repositories to have been cloned to its local disk. Changes are then made against these local repositories, after which they get pushed to Github.

However, the need for local repositories makes it unsafe to run multiple instances of this tool. This is because every instance has its commands executed against the same repository. Hence, multiple active instances could have their commands inadvertently interpolated, leaving the local repositories in an unexpected state.

The solution to this was to completely remove the need for a local repository and instead have everything done through the wonderful Github API. This article is really just a reminder to myself about some Github functionality that I discovered while looking into this.




3 challenges:

def branch_contains_sha?(repo, branch, sha)
    ["behind", "identical"].include?(compare(repo, branch, sha).status)
  end

  def create_branch_from_sha(repo, branch, sha)
    begin
      create_ref(repo, "heads/#{branch}", sha)
    rescue Octokit::UnprocessableEntity
      # ignore 'reference already exists' error
    end
  end

  def update_branch_to_sha(repo, branch, sha, force = true)
    update_ref(repo, "heads/#{branch}", sha, force)
  end

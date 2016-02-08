+++
date = "2015-04-19T20:17:35+00:00"
title = "Writing your own rspec retry mechanism"
type = "post"
ogtype = "article"
topics = [ "ruby", "rails" ]
+++

Imagine you have an rspec test suite filled with [system tests](http://david.heinemeierhansson.com/2014/tdd-is-dead-long-live-testing.html). Each system test simulates how a real user would interact with your app by opening a browser session through which it fills out text fields, clicks on buttons, and sends data to public endpoints. Unfortunately, browser drivers are not without bugs and sometimes your tests will fail because of them. Wouldn't it be nice if we could automatically retry these failed tests?

Note that any code shown in this post is only guaranteed to work with rspec 3.3. In the past I've written similar code for other rspec versions as well though. So don't worry, it shouldn't be too hard to get all of this to work on whatever rspec version you find yourself using.

### Rspec formatters

Rspec generates its command line output by using formatters that receive messages on events like `example_passed` and `example_failed`. We can use these hooks to help us keep track of failed tests by writing their identifiers to a text file. The `FailureFormatter` shown below shows how to do this.

```ruby
# failure_formatter.rb
require 'rspec/core/formatters/progress_formatter'

class FailureFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self, :example_failed

  def example_failed(notification)
    super
    File.open('tests_failed', 'a') do |file|
      file.puts(notification.example.full_description)
    end
  end
end
```

Let's see how our test suite behaves when we try to run it with this particular formatter. First, let's prepare some example tests. We'll create two tests. One of which will always pass, while the other one will always fail.

```ruby
# my_fake_tests_spec.rb
describe 'my fake tests', :type => :feature do

  it 'should do this' do
    expect(true).to eq true
  end

  it 'should do that' do
    expect(false).to eq true
  end
end
```

Having done that, we can now run our tests with the `FailureFormatter` we wrote earlier. As you can see, we'll have to pass both `--require` and `--format` params in order to get this working. I've also set the `--no-fail-fast` flag to prevent our test suite from stopping upon encountering its first failure.

```bash
$ bundle exec rspec --require ./spec/formatters/failure_formatter.rb --format FailureFormatter --no-fail-fast

.F

Failures:

  1) my fake tests should do that
     Failure/Error: expect(false).to eq true

       expected: true
            got: false

       (compared using ==)
     # ./spec/my_fake_tests_spec.rb:8:in `block (2 levels) in <top (required)>'

Finished in 0.02257 seconds (files took 0.11574 seconds to load)
2 examples, 1 failure

Failed examples:

rspec ./spec/my_fake_tests_spec.rb:7 # my fake tests should do that
```

After running this, we should now have a tests_failed file that holds a single line describing our failed test. As we can see in the snippet below, this is indeed the case.

```bash
$ cat tests_failed

my fake tests should do that
```

Take a moment to reflect on what we have just done. By writing just a few lines of code we have effectively created a logging mechanism that will keep track of failed tests for us. In the next section we will look at how we can make use of this mechanism to automatically have failed tests rerun for us.

### Creating the retry task




simulating browser sessions is still not entirely without pains and sometimes your tests will fail because of bugs in your browser session simulation libraries.

Having had a lot of first-hand experience with an app that started out as pure Ruby On Rails, but whose newer features are a mix of RoR and Ember.js, I can say with some authority that sometimes your tests will break because of bugs in your browser session simulation software.

 Ruby On Raiapp whose older product features are pure Ruby on Rails, while the newer ones are a mix of  onpart rails, part Ember.js

whileWhile this sounds idealUnfortunately, sometimes the software

through which it validates your app's correctness by checking how it reacts to textfields getting filledm buttons getting pressed, and data hitting its endpoints.

sending data, pressing buttons, and filling text fields

 filling text fields, pressing buttons, and sending data to public endpoints. In short, each system test checks for bugs in the expected user experience.


from the user's point of view by run a browser against

simulating how a real user would interact with your app

're using your rspec test suite to drive

run fullstack system tests.
Sometimes you want your rspec tests to retry themselves in case of falure.

rspec 3 - the goal: retry mechanism for failed test. Retries should be clearly visible in output.
General approach: run tests, mark which tests failed, rerun with just those tests
How? Formatters! Explain we can write a formatter that writes each failed test to a fail.
We'll need to wrap our test runner logic in a script. This is where Ruby comes in.
Check that our system call gives us access to stdout and exit code.
logging failed tests is eaier for demonstaring puproses. Call this failure_log
nope, better to have a success log
f we dnt use ChildProcess, how does it react to kill -9? Does the childprocess get killed? or can we have parentless processes?
What's the impact of this on the exit code?
you need to list tests!

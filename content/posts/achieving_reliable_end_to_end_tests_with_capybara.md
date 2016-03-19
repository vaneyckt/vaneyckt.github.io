+++
date = "2016-03-17T19:12:21+00:00"
title = "Achieving reliable end-to-end tests with Capybara"
type = "post"
ogtype = "article"
topics = [ "ruby" ]
+++

End-to-end [system tests](http://david.heinemeierhansson.com/2014/tdd-is-dead-long-live-testing.html) are a great tool to help you test your application. This type of test simulates a customer interacting with your app by browsing your site, filling out text fields, and clicking buttons. You can create a fully automated end-to-end regression test suite by focusing on system tests that capture the kind of customer behavior that leads to the most communication between your backend components. Such a suite will help you keep bugs out of your product without having to invest heavily in manual regression testing.

So if system tests are so great, how come we don't see them being used everywhere? As it turns out, creating stable end-to-end tests is [hard](https://bibwild.wordpress.com/2016/02/18/struggling-towards-reliable-capybara-javascript-testing/), [really hard](http://googletesting.blogspot.ie/2015/04/just-say-no-to-more-end-to-end-tests.html). Dealing with undocumented behavior of your browser driver is just the first of your worries. The real trouble starts when the pages you're writing tests for rely heavily on asynchronous javascript actions, as these can make it really hard for your tests to detect when a page has finished rendering.

In this article I am going to walk you through every step of my approach towards building a test suite that is currently being used for automated regression testing of a rails app. About half the pages of this particular rails app depend on javascript and jQuery, while the other half were created with the Ember.js framework. So there's going to be plenty of javascript logic that could confuse my tests something fierce.

I am going to talk about all aspects related to dealing with this onslaught of javascript. I will speak about the best way to arrange your tests, which libraries to use and their respective configurations, as well as go into detail about how we can monkeypatch Capybara in order to greatly improve test reliability. The completed code of this article can be found [here](todo).

### Page objects

 A page object is a wrapper around a html page. Its goal is to act as a high-level abstraction of the underlying page, thereby allowing you to write code that interacts with the elements on the page without you having to be aware of the page's html. Page objects are going to form the very core of our tests, so let's take the time to get acquainted with them.






- the core of how to arrange your tests <- transition from previous paragraph
- what asre page objects
- why are we going to use them
- introduction to siteprism
- talks to the page through Capybara
- is great: if all our tests are driven through page objects, then the vast majority from our test suite to Capybara will go through Site Prism. This means we just need to figure out which Capybara methods are being used by SitePrism, and ensure that these will function correctly when dealing with large amounts of javascript. Don't worry if this sounds confusing, we will go into detail into this in the next section.

https://github.com/natritmeyer/site_prism


### Choosing and configuring libraries


### Capybara monkeypatching




 want to introduce my approach to end-to-end system tests.

This article starts by investigating how rspec formatters can be used to help us keep track of failed tests. Next, we'll use this information to take a first stab at creating a rake task that can automatically retry failed tests. Lastly, we'll explore how to further improve our simple rake task so as to make it ready for use in production.

Note that any code shown in this post is only guaranteed to work with rspec 3.3. In the past I've written similar code for other rspec versions as well though. So don't worry, it shouldn't be too hard to get all of this to work on whatever rspec version you find yourself using.

what are we gonna show in this article. I am going to walk you through every step of our solution to fully automated stable end-to-end system tests for an internal rails app, some pages of which are built primarily with javascript and jquery, otehr pages of which are built entirely with the help of Ember.js. In short, there'sa lot of javascript here that can confouse yourt tests. I will be talking about hoe to arrange your tests (page objects!), which frameworks to use, explain configuration choices, and walk you through how to mnkeypatch Capybara to achieve reliable tests in the face of an onslaught of javascript. Also make code available in github repo.

- Before we start I want to reiterate that this will ONLY work for pages built with jquery or Ember.js. Although by the end of thisarticle you should be able to understand how to come up with solution that involve other asynchrinous javascript frontedn frameworks.

As This can make it really hard for a

the bugs and unfoNot only do you need to be aware of the bugs and undocumented behavior of your browser driver, but



#1: Name the enemy
#2: Answer “Why now?”
#3: Show the promised land before explaining how you’ll get there
#4: Identify obstacles—then explain how you’ll overcome them
#5: Present evidence that you’re not just blowing hot air

Rspec generates its command line output by relying on formatters that receive messages on events like example_passed and example_failed. We can use these hooks to help us keep track of failed tests by having them write the descriptions of failed tests to a text file named tests_failed. Our FailureFormatter class does just that.

- system tests are cool [link]. introduce what system tests do, what problems they solve. Especially nice if you got a complex backend stack. Have these tests emulate behaviour that involves the max. amount of backend components. If everything works thhen yo can be relatively certain things are okay. Take this a step further: fully automated regression

- this stuff is hard, really hard. Lots of people having trouble with stability. Link to google blog, links to two articles on here https://bibwild.wordpress.com/2016/02/18/struggling-towards-reliable-capybara-javascript-testing/. Can feel like playing a game of whack-a-mole. Name the problems with javascript: hard to decide when a page has finished rendering at the est of times, asynchrinous javascript frameworks are making this even worse.

- what are we gonna show in this article. I am going to walk you through every step of our solution to fully automated stable end-to-end system tests for an internal rails app, some pages of which are built primarily with javascript and jquery, otehr pages of which are built entirely with the help of Ember.js. In short, there'sa lot of javascript here that can confouse yourt tests. I will be talking about hoe to arrange your tests (page objects!), which frameworks to use, explain configuration choices, and walk you through how to mnkeypatch Capybara to achieve reliable tests in the face of an onslaught of javascript. Also make code available in github repo.

- Before we start I want to reiterate that this will ONLY work for pages built with jquery or Ember.js. Although by the end of thisarticle you should be able to understand how to come up with solution that involve other asynchrinous javascript frontedn frameworks.

### Pagse OObjects and the SitePrism library

- what asre page objects
- why are we going to use them
- introduction to siteprism
- talks to the page through Capybara
- is great: if all our tests are driven through page objects, then the vast majority from our test suite to Capybara will go through Site Prism. This means we just need to figure out which Capybara methods are being used by SitePrism, and ensure that these will function correctly when dealing with large amounts of javascript. Don't worry if this sounds confusing, we will go into detail into this in the next section.



Imagine you have an rspec test suite filled with [system tests](http://david.heinemeierhansson.com/2014/tdd-is-dead-long-live-testing.html). Each system test simulates how a real user would interact with your app by opening a browser session through which it fills out text fields, clicks on buttons, and sends data to public endpoints. Unfortunately, browser drivers are not without bugs and sometimes your tests will fail because of these. Wouldn't it be nice if we could automatically retry these failed tests?

This article starts by investigating how rspec formatters can be used to help us keep track of failed tests. Next, we'll use this information to take a first stab at creating a rake task that can automatically retry failed tests. Lastly, we'll explore how to further improve our simple rake task so as to make it ready for use in production.

Note that any code shown in this post is only guaranteed to work with rspec 3.3. In the past I've written similar code for other rspec versions as well though. So don't worry, it shouldn't be too hard to get all of this to work on whatever rspec version you find yourself using.

### Rspec formatters

Rspec generates its command line output by relying on formatters that receive messages on events like `example_passed` and `example_failed`. We can use these hooks to help us keep track of failed tests by having them write the descriptions of failed tests to a text file named `tests_failed`. Our `FailureFormatter` class does just that.

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

We'll soon have a look at how tests behave when we try to run them with the formatter shown above. But first, let's prepare some example tests. We'll create two tests. One of which will always pass, and another one which will always fail.

```ruby
# my_fake_tests_spec.rb
describe 'my fake tests', :type => :feature do

  it 'this scenario should pass' do
    expect(true).to eq true
  end

  it 'this scenario should fail' do
    expect(false).to eq true
  end
end
```

Having done that, we can now run our tests with the `FailureFormatter` we wrote earlier. As you can see below, we'll have to pass both `--require` and `--format` params in order to get our formatter to work. I'm also using the `--no-fail-fast` flag so as to prevent our test suite from exiting upon encountering its first failure.

```bash
$ bundle exec rspec --require ./spec/formatters/failure_formatter.rb --format FailureFormatter --no-fail-fast
.F

Failures:

  1) my fake tests this scenario should fail
     Failure/Error: expect(false).to eq true

       expected: true
            got: false

       (compared using ==)
     # ./spec/my_fake_tests_spec.rb:8:in `block (2 levels) in <top (required)>'

Finished in 0.02272 seconds (files took 0.0965 seconds to load)
2 examples, 1 failure

Failed examples:

rspec ./spec/my_fake_tests_spec.rb:7 # my fake tests this scenario should fail
```

After running this, we should now have a `tests_failed` file that contains a single line describing our failed test. As we can see in the snippet below, this is indeed the case.

```bash
$ cat tests_failed

my fake tests this scenario should fail
```

Take a moment to reflect on what we have just done. By writing just a few lines of code we have effectively created a logging mechanism that will help us keep track of failed tests. In the next section we will look at how we can make use of this mechanism to automatically rerun failed tests.

### First pass at creating the retry task

In this section we will create a rake task that runs our rspec test suite and automatically retries any failed tests. The finished rake task is shown below. For now, have a look at this code and then we'll go over its details in the next few paragraphs.

```ruby
require 'fileutils'

task :rspec_with_retries, [:max_tries] do |_, args|
  max_tries = args[:max_tries].to_i

  # construct initial rspec command
  command = 'bundle exec rspec --require ./spec/formatters/failure_formatter.rb --format FailureFormatter --no-fail-fast'

  max_tries.times do |t|
    puts "\n"
    puts '##########'
    puts "### STARTING TEST RUN #{t + 1} OUT OF A MAXIMUM OF #{max_tries}"
    puts "### executing command: #{command}"
    puts '##########'

    # delete tests_failed file left over by previous run
    FileUtils.rm('tests_failed', :force => true)

    # run tests
    puts `#{command}`

    # early out
    exit 0 if $?.exitstatus.zero?
    exit 1 if (t == max_tries - 1)

    # determine which tests need to be run again
    failed_tests = []
    File.open('tests_failed', 'r') do |file|
      failed_tests = file.readlines.map { |line| "\"#{line.strip}\"" }
    end

    # construct command to rerun just the failed tests
    command  = ['bundle exec rspec']
    command += Array.new(failed_tests.length, '-e').zip(failed_tests).flatten
    command += ['--require ./spec/formatters/failure_formatter.rb --format FailureFormatter --no-fail-fast']
    command = command.join(' ')
  end
end
```

The task executes the `bundle exec rspec` command a `max_tries` number of times. The first iteration runs the full rspec test suite with the `FailureFormatter` class and writes the descriptions of failed tests to a `tests_failed` file. Subsequent iterations read from this file and use the [-e option](https://relishapp.com/rspec/rspec-core/v/3-3/docs/command-line/example-option) to rerun the tests listed there.

Note that these subsequent iterations use the `FailureFormatter` as well. This means that any tests that failed during the second iteration will get written to the `tests_failed` file to be retried by the third iteration. This continues until we reach the max number of iterations or until one of our iterations has all its tests pass.

Every iteration deletes the `tests_failed` file from the previous iteration. For this we use the `FileUtils.rm` method with the `:force` flag set to `true`. This flag ensures that the program doesn't crash in case the `tests_failed` file doesn't exist. The above code relies on backticks to execute the `bundle exec rspec` subprocess. Because of this we need to use the global variable `$?` to access the exit status of this subprocess.

Below you can see the output of a run of our rake task. Notice how the first iteration runs both of our tests, whereas the second and third iterations rerun just the failed test. This shows our retry mechanism is indeed working as expected.

```bash
$ rake rspec_with_retries[3]

##########
### STARTING TEST RUN 1 OUT OF A MAXIMUM OF 3
### executing command: bundle exec rspec --require ./spec/formatters/failure_formatter.rb --format FailureFormatter --no-fail-fast
##########
.F

Failures:

  1) my fake tests this scenario should fail
     Failure/Error: expect(false).to eq true

       expected: true
            got: false

       (compared using ==)
     # ./spec/my_fake_tests_spec.rb:8:in `block (2 levels) in <top (required)>'

Finished in 0.02272 seconds (files took 0.0965 seconds to load)
2 examples, 1 failure

Failed examples:

rspec ./spec/my_fake_tests_spec.rb:7 # my fake tests this scenario should fail


##########
### STARTING TEST RUN 2 OUT OF A MAXIMUM OF 3
### executing command: bundle exec rspec -e "my fake tests this scenario should fail" --require ./spec/formatters/failure_formatter.rb --format FailureFormatter --no-fail-fast
##########
Run options: include {:full_description=>/my\ fake\ tests\ this\ scenario\ should\ fail/}
F

Failures:

  1) my fake tests this scenario should fail
     Failure/Error: expect(false).to eq true

       expected: true
            got: false

       (compared using ==)
     # ./spec/my_fake_tests_spec.rb:8:in `block (2 levels) in <top (required)>'

Finished in 0.02286 seconds (files took 0.09094 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/my_fake_tests_spec.rb:7 # my fake tests this scenario should fail


##########
### STARTING TEST RUN 3 OUT OF A MAXIMUM OF 3
### executing command: bundle exec rspec -e "my fake tests this scenario should fail" --require ./spec/formatters/failure_formatter.rb --format FailureFormatter --no-fail-fast
##########
Run options: include {:full_description=>/my\ fake\ tests\ this\ scenario\ should\ fail/}
F

Failures:

  1) my fake tests this scenario should fail
     Failure/Error: expect(false).to eq true

       expected: true
            got: false

       (compared using ==)
     # ./spec/my_fake_tests_spec.rb:8:in `block (2 levels) in <top (required)>'

Finished in 0.02378 seconds (files took 0.09512 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/my_fake_tests_spec.rb:7 # my fake tests this scenario should fail
```

The goal of this section was to introduce the general idea behind our retry mechanism. There are however several shortcomings in the code that we've shown here. The next section will focus on identifying and fixing these.

### Perfecting the retry task

The code in the previous section isn't all that bad, but there are a few things related to the `bundle exec rspec` subprocess that we can improve upon. In particular, using backticks to initiate subprocesses has several downsides:

- the standard output stream of the subprocess gets written into a buffer which we cannot print until the subprocess finishes
- the standard error stream does not even get written to this buffer
- the backticks approach does not return the id of the subprocess to us

This last downside is especially bad as not having the subprocess id makes it hard for us to cancel the subprocess in case the rake task gets terminated. This is why I prefer to use the [childprocess gem](https://github.com/jarib/childprocess) for handling subprocesses instead.


```ruby
require 'fileutils'
require 'childprocess'

task :rspec_with_retries, [:max_tries] do |_, args|
  max_tries = args[:max_tries].to_i

  # exit hook to ensure rspec process gets stopped when CTRL+C (SIGTERM is pressed)
  # needs to be set outside the times loop as otherwise each iteration would add its
  # own at_exit hook
  process = nil
  at_exit do
    process.stop unless process.nil?
  end

  # construct initial rspec command
  command = ['bundle', 'exec', 'rspec', '--require', './spec/formatters/failure_formatter.rb', '--format', 'FailureFormatter', '--no-fail-fast']

  max_tries.times do |t|
    puts "\n"
    puts '##########'
    puts "### STARTING TEST RUN #{t + 1} OUT OF A MAXIMUM OF #{max_tries}"
    puts "### executing command: #{command}"
    puts '##########'

    # delete tests_failed file left over by previous run
    FileUtils.rm('tests_failed', :force => true)

    # run tests in separate process
    process = ChildProcess.build(*command)
    process.io.inherit!
    process.start
    process.wait

    # early out
    exit 0 if process.exit_code.zero?
    exit 1 if (t == max_tries - 1)

    # determine which tests need to be run again
    failed_tests = []
    File.open('tests_failed', 'r') do |file|
      failed_tests = file.readlines.map { |line| line.strip }
    end

    # construct command to rerun just the failed tests
    command  = ['bundle', 'exec', 'rspec']
    command += Array.new(failed_tests.length, '-e').zip(failed_tests).flatten
    command += ['--require', './spec/formatters/failure_formatter.rb', '--format', 'FailureFormatter', '--no-fail-fast']
  end
end
```

As we can see from the line `process = ChildProcess.build(*command)`, this gem makes it trivial to obtain the subprocess id. This then allows us to write an `at_exit` hook that shuts this subprocess down upon termination of our rake task. For example, using ctrl+c to cease the rake task will now cause the rspec subprocess to stop as well.

This gem also makes it super easy to inherit the stdout and stderr streams from the parent process (our rake task). This means that anything that gets written to the stdout and stderr streams of the subprocess will now be written directly to the stdout and stderr streams of our rake task. Or in other words, our rspec subprocess is now able to output directly to the rake task's terminal session. Having made these improvements, our `rspec_with_retries` task is now ready for use in production.

### Conclusion

I hope this post helped some people out there who find themselves struggling to deal with flaky tests. Please note that a retry mechanism such as this is really only possible because of rspec's powerful formatters. Get in touch if you have any examples of other cool things built on top of this somewhat underappreciated feature!

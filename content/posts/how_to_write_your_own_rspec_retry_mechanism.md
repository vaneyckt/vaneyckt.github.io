+++
date = "2016-01-17T20:17:35+00:00"
title = "How to write your own rspec retry mechanism"
type = "post"
ogtype = "article"
topics = [ "ruby", "rails" ]
+++

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

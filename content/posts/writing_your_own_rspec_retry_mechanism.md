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

  it 'this scenario should pass' do
    expect(true).to eq true
  end

  it 'this scenario should fail' do
    expect(false).to eq true
  end
end
```

Having done that, we can now run our tests with the `FailureFormatter` we wrote earlier. As you can see, we'll have to pass both `--require` and `--format` params in order to get this working. I've also set the `--no-fail-fast` flag to prevent our test suite from stopping upon encountering its first failure.

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

After running this, we should now have a tests_failed file that holds a single line describing our failed test. As we can see in the snippet below, this is indeed the case.

```bash
$ cat tests_failed

my fake tests this scenario should fail
```

Take a moment to reflect on what we have just done. By writing just a few lines of code we have effectively created a logging mechanism that will keep track of failed tests for us. In the next section we will look at how we can make use of this mechanism to automatically rerun failed tests.

### Creating the retry task

In this section we are going to create a rake task that runs our rspec test suite and handles retrying our failed tests.

backticks don't capture stderr

also bad with kill -9

2 examples, 1 failure at first run
1 example, 1 failure at next runs


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

childprocess gives you stderr
as well as kill -9 safety

### Perfecting the retry task

ctrl+c (handy for CI machines)
child process also inheriting stderr
output is the same
array notation for commands
no more puts, as we are inheriting the stream


```ruby
require 'fileutils'
require 'childprocess'

task :rspec_with_retries, [:max_tries] do |_, args|
  max_tries = args[:max_tries].to_i

  # exit hook to ensure rspec process gets stopped when CTRL+C (SIGTERM is pressed)
  # needs to be set outside the times loop as otherwise each iteration would add its
  # own at_exit hook
  process = nil
  at_exit { process.stop unless process.nil? }

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
      failed_tests = file.readlines.map { |line| "#{line.strip}" }
    end

    # construct command to rerun just the failed tests
    command  = ['bundle', 'exec', 'rspec']
    command += Array.new(failed_tests.length, '-e').zip(failed_tests).flatten
    command += ['--require', './spec/formatters/failure_formatter.rb', '--format', 'FailureFormatter', '--no-fail-fast']
  end
end
```

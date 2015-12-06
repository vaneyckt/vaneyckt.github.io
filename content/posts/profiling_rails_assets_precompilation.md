+++
date = "2013-09-01T21:01:02+00:00"
title = "Profiling rails assets precompilation"
type = "post"
ogtype = "article"
tags = [ "rails" ]
+++

Assets precompilation on rails can take a fair bit of time. This is especially annoying in scenarios where you want to deploy your app multiple times a day. Let's see if we can come up with a way to actually figure out where all this time is being spent. Also, while I will be focusing on rails 3.2 in this post, the general principle should be easy enough to apply to other rails versions.

Our first call of action is finding the assets precompilation logic. A bit of digging will turn up the [assets.rake file](https://github.com/rails/rails/blob/3-2-stable/actionpack/lib/sprockets/assets.rake) for rails 3.2. The relevant code starts on lines 59-67 and from there on out invokes methods throughout the entire file.

```ruby
# lines 59-67 of assets.rake
task :all do
  Rake::Task["assets:precompile:primary"].invoke
  # We need to reinvoke in order to run the secondary digestless
  # asset compilation run - a fresh Sprockets environment is
  # required in order to compile digestless assets as the
  # environment has already cached the assets on the primary
  # run.
  if Rails.application.config.assets.digest
    ruby_rake_task("assets:precompile:nondigest", false)
  end
end
```

When we follow the calls made by the code above we can see that the actual compilation takes place on lines 50-56 of assets.rake and is done by the compile method of the [Sprockets::StaticCompiler class](https://github.com/rails/rails/blob/3-2-stable/actionpack/lib/sprockets/static_compiler.rb).

```ruby
# compile method of Sprockets::StaticCompiler class
def compile
  manifest = {}
  env.each_logical_path(paths) do |logical_path|
    if asset = env.find_asset(logical_path)
      digest_path = write_asset(asset)
      manifest[asset.logical_path] = digest_path
      manifest[aliased_path_for(asset.logical_path)] = digest_path
    end
  end
  write_manifest(manifest) if @manifest
end
```

Now that we know which code does the compiling, we can think of two ways to add some profiling to this. We could checkout the rails repo from Github, modify it locally and point our Gemfile to our modified local version of rails. Or, we could create a new rake task and monkey patch the compile method of the Sprockets::StaticCompiler class. We'll go with the second option here as it is the more straightforward to implement.

We'll create a new rake file in the /lib/tasks folder of our rails app and name it `profile_assets_precompilation.rake`. We then copy the contents of assets.rake into it, and wrap this code inside a new 'profile' namespace so as to avoid conflicts. At the top of this file we'll also add our monkey patched compile method so as to make it output profiling info. The resulting file should look like shown below.

```ruby
namespace :profile do
  # monkey patch the compile method to output compilation times
  module Sprockets
    class StaticCompiler
      def compile
        manifest = {}
        env.each_logical_path(paths) do |logical_path|
          start_time = Time.now.to_f

          if asset = env.find_asset(logical_path)
            digest_path = write_asset(asset)
            manifest[asset.logical_path] = digest_path
            manifest[aliased_path_for(asset.logical_path)] = digest_path
          end

          # our profiling code
          duration = Time.now.to_f - start_time
          puts "#{logical_path} - #{duration.round(3)} seconds"
        end
        write_manifest(manifest) if @manifest
      end
    end
  end

  # contents of assets.rake
  namespace :assets do
    def ruby_rake_task(task, fork = true)
      env    = ENV['RAILS_ENV'] || 'production'
      groups = ENV['RAILS_GROUPS'] || 'assets'
      args   = [$0, task,"RAILS_ENV=#{env}","RAILS_GROUPS=#{groups}"]
      args << "--trace" if Rake.application.options.trace
      if $0 =~ /rake\.bat\Z/i
        Kernel.exec $0, *args
      else
        fork ? ruby(*args) : Kernel.exec(FileUtils::RUBY, *args)
      end
    end

    # We are currently running with no explicit bundler group
    # and/or no explicit environment - we have to reinvoke rake to
    # execute this task.
    def invoke_or_reboot_rake_task(task)
      if ENV['RAILS_GROUPS'].to_s.empty? || ENV['RAILS_ENV'].to_s.empty?
        ruby_rake_task task
      else
        Rake::Task[task].invoke
      end
    end

    desc "Compile all the assets named in config.assets.precompile"
    task :precompile do
      invoke_or_reboot_rake_task "assets:precompile:all"
    end

    namespace :precompile do
      def internal_precompile(digest=nil)
        unless Rails.application.config.assets.enabled
          warn "Cannot precompile assets if sprockets is disabled. Please set config.assets.enabled to true"
          exit
        end

        # Ensure that action view is loaded and the appropriate
        # sprockets hooks get executed
        _ = ActionView::Base

        config = Rails.application.config
        config.assets.compile = true
        config.assets.digest  = digest unless digest.nil?
        config.assets.digests = {}

        env      = Rails.application.assets
        target   = File.join(Rails.public_path, config.assets.prefix)
        compiler = Sprockets::StaticCompiler.new(env,
                                                 target,
                                                 config.assets.precompile,
                                                 :manifest_path => config.assets.manifest,
                                                 :digest => config.assets.digest,
                                                 :manifest => digest.nil?)
        compiler.compile
      end

      task :all do
        Rake::Task["assets:precompile:primary"].invoke
        # We need to reinvoke in order to run the secondary digestless
        # asset compilation run - a fresh Sprockets environment is
        # required in order to compile digestless assets as the
        # environment has already cached the assets on the primary
        # run.
        ruby_rake_task("assets:precompile:nondigest", false) if Rails.application.config.assets.digest
      end

      task :primary => ["assets:environment", "tmp:cache:clear"] do
        internal_precompile
      end

      task :nondigest => ["assets:environment", "tmp:cache:clear"] do
        internal_precompile(false)
      end
    end

    desc "Remove compiled assets"
    task :clean do
      invoke_or_reboot_rake_task "assets:clean:all"
    end

    namespace :clean do
      task :all => ["assets:environment", "tmp:cache:clear"] do
        config = Rails.application.config
        public_asset_path = File.join(Rails.public_path, config.assets.prefix)
        rm_rf public_asset_path, :secure => true
      end
    end

    task :environment do
      if Rails.application.config.assets.initialize_on_precompile
        Rake::Task["environment"].invoke
      else
        Rails.application.initialize!(:assets)
        Sprockets::Bootstrap.new(Rails.application).run
      end
    end
  end
end
```

Now we can run `bundle exec rake profile:assets:precompile` to precompile our assets while outputting profiling info. Hopefully we can now finally figure out why this is always taking so long :).

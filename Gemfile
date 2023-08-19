source "https://rubygems.org"

gem "CleevioFastlane", '~> 3.0.0', git: 'git@gitlab.cleevio.cz:cleevio-dev-ios/ci-ios.git', glob: 'fastlane/*.gemspec'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)

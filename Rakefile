require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/extensiontask'
require 'rake/testtask'
include Rake::DSL

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

Rake::ExtensionTask.new('time_bandits') do |ext|
  ext.lib_dir = 'lib/time_bandits'
end

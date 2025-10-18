#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/*_test.rb"]
  t.ruby_opts = ["-w"]
  t.verbose = true
end

require "reissue/gem"

Reissue::Task.create do |task|
  task.version_file = "lib/casting/version.rb"
  task.fragment = :git
end

task default: :test

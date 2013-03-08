# require 'bundler/gem_tasks'
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'

# encoding: UTF-8
require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace']
end

task :default => :spec
# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'redis_analytics/version'

Gem::Specification.new do |spec|
  spec.name        = "redis_analytics"
  spec.version     = Rack::RedisAnalytics::VERSION
  spec.date        = '2013-02-15'
  spec.authors     = ["Schubert Cardozo"]
  spec.email       = ["cardozoschubert@gmail.com"]
  spec.homepage    = "https://github.com/saturnine/redis_analytics"
  spec.summary     = %q{Analytics for your rails apps using Redis}
  spec.description = %q{Analytics for your rails apps using Redis}

  spec.rubyforge_project = "redis_analytics"

  spec.files         = Dir.glob("**/*.rb")
  #spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency('rack')
  spec.add_runtime_dependency('redis')
  spec.add_runtime_dependency('browser')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('mocha')

  spec.required_ruby_version = '>= 1.9.2'
end

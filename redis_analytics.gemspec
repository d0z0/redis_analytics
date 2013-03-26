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

  spec.files          = Dir.glob("**/*")
  #spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths  = ["lib"]

  spec.add_runtime_dependency('rack', '>= 1.4.0')
  spec.add_runtime_dependency('redis', '>= 3.0.2')
  spec.add_runtime_dependency('browser', '>= 0.1.6')
  spec.add_runtime_dependency('sinatra', '>= 1.3.3')
  spec.add_runtime_dependency('geoip', '>= 1.2.1')
  spec.add_runtime_dependency('activesupport', '>= 3.2.0')

  spec.add_development_dependency('rake', '>= 10.0.3')
  spec.add_development_dependency('rspec', '>= 2.11.0')
  spec.add_development_dependency('mocha', '>= 0.12.7')

  spec.required_ruby_version = '>= 1.9.2'
end

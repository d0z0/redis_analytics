# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'redis_analytics/version'

Gem::Specification.new do |spec|
  spec.name        = "redis_analytics"
  spec.version     = RedisAnalytics::VERSION
  spec.date        = Time.now.strftime('%Y-%m-%d')
  spec.authors     = ["Schubert Cardozo"]
  spec.email       = ["cardozoschubert@gmail.com"]
  spec.homepage    = "https://github.com/saturnine/redis_analytics"
  spec.summary     = %q{Fast and efficient web analytics for Rack apps}
  spec.description = %q{A gem that provides a Redis based web analytics solution for your rack-compliant apps. It gives you detailed analytics about visitors, unique visitors, browsers, OS, visitor recency, traffic sources and more}

  spec.rubyforge_project = "redis_analytics"

  spec.files          = Dir.glob("**/*")

  # spec.executables = ['redis_analytics_dashboard']
  # spec.default_executable = 'redis_analytics_dashboard'
  spec.require_paths  = ["lib"]

  spec.add_runtime_dependency 'rails', '>= 3.2.0', '< 5'
  spec.add_runtime_dependency 'jquery-rails'
  spec.add_runtime_dependency 'sqlite3'
  spec.add_runtime_dependency 'redis'
  spec.add_runtime_dependency 'browser'
  spec.add_runtime_dependency 'geoip'
  spec.add_runtime_dependency 'json'

  spec.add_development_dependency 'fakeredis'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'

  spec.required_ruby_version = '>= 1.9.2'
end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'redis_analytics/version'

Gem::Specification.new do |spec|
  spec.name        = "redis_analytics"
  spec.license	   = 'MIT'
  spec.version     = RedisAnalytics::VERSION
  spec.date        = Time.now.strftime('%Y-%m-%d')
  spec.authors     = ["Schubert Cardozo"]
  spec.email       = ["cardozoschubert@gmail.com"]
  spec.homepage    = "https://github.com/saturnine/redis_analytics"
  spec.summary     = %q{Fast and efficient web analytics for Rack apps}
  spec.description = %q{A gem that provides a Redis based web analytics solution for your rack-compliant apps. It gives you detailed analytics about visitors, unique visitors, browsers, OS, visitor recency, traffic sources and more}

  spec.rubyforge_project = "redis_analytics"

  spec.files          = Dir.glob("**/*")

  spec.require_paths  = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_dependency 'rack', '>= 1.2.0'
  spec.add_dependency 'redis', ["< 5", ">= 2.2"]
  spec.add_dependency 'jquery-rails', '~> 4.3'
  spec.add_dependency 'browser', '>= 2.6', '< 4.0'
  spec.add_dependency 'geoip', '~> 1.6'

  spec.add_development_dependency 'fakeredis'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'

end

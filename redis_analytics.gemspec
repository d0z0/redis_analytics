# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'redis_analytics/version'

Gem::Specification.new do |spec|
  spec.name        = "redis_analytics"
  spec.version     = Rack::RedisAnalytics::VERSION
  spec.date        = Time.now.strftime('%Y-%m-%d')
  spec.authors     = ["Schubert Cardozo"]
  spec.email       = ["cardozoschubert@gmail.com"]
  spec.homepage    = "https://github.com/saturnine/redis_analytics"
  spec.summary     = %q{Fast and efficient web analytics for Rack apps}
  spec.description = %q{A gem that provides a Redis based web analytics solution for your rack-compliant apps. It gives you detailed analytics about visitors, unique visitors, browsers, OS, visitor recency, traffic sources and more}

  spec.rubyforge_project = "redis_analytics"

  spec.files          = Dir.glob("**/*")

  spec.executables = ['redis_analytics_dashboard']
  spec.default_executable = 'redis_analytics_dashboard'
  spec.require_paths  = ["lib"]

  spec.add_runtime_dependency('rack', '~> 1.5.2')
  spec.add_runtime_dependency('redis', '~> 3.0.2')
  spec.add_runtime_dependency('browser', '~> 0.1.6')
  spec.add_runtime_dependency('sinatra', '~> 1.4.2')
  spec.add_runtime_dependency('sinatra-assetpack', '~> 0.2.5')
  # spec.add_runtime_dependency('geoip', '~> 1.2.1')
  # spec.add_runtime_dependency("geocoder", "~> 1.1.8")
  spec.add_runtime_dependency('json', '~> 1.8.0')
  spec.add_runtime_dependency('activesupport', '>= 3.2.0')

  spec.add_development_dependency('rake', '~> 10.0.3')
  spec.add_development_dependency('rspec', '~> 2.13.0')
  spec.add_development_dependency('guard-rspec', '~> 3.0.1')
  spec.add_development_dependency('mocha', '~> 0.14.0')
  spec.add_development_dependency('rack-test', '~> 0.6.2')
  spec.add_development_dependency('simplecov', '~> 0.7.1')
  spec.add_development_dependency('coveralls', '~> 0.6.7')

  spec.required_ruby_version = '~> 1.9.2'
end

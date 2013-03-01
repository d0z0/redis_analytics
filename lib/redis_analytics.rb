require 'rack'
require 'redis'
require 'browser'
require 'sinatra'

require 'redis_analytics'
require 'redis_analytics/version'
require 'redis_analytics/configuration'
require 'redis_analytics/analytics'
require 'redis_analytics/dashboard/dashboard'
require 'redis_analytics/mapper'
require 'redis_analytics/helpers'
require 'redis_analytics/railtie' if defined? Rails::Railtie

module Rack
  module RedisAnalytics
    extend Configuration
  end
end

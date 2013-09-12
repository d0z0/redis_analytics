require 'rack'
require 'redis'
require 'browser'
require 'sinatra'
require 'geoip'

require 'redis_analytics'
require 'redis_analytics/version'
require 'redis_analytics/filter'
require 'redis_analytics/configuration'
require 'redis_analytics/analytics'
require 'redis_analytics/time_ext'
require 'redis_analytics/helpers'
require 'redis_analytics/api'
require 'redis_analytics/dashboard'

require 'redis_analytics/tracker'
require 'redis_analytics/railtie' if defined? Rails::Railtie

module Rack
  module RedisAnalytics
    extend Configuration
  end
end

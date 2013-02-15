require 'rack'
require 'redis'

require 'redis_analytics'
require 'redis_analytics/version'
require 'redis_analytics/configuration'
require 'redis_analytics/analytics'
require 'redis_analytics/railtie' if defined? Rails

module Rack
  module RedisAnalytics
    extend Configuration
  end
end

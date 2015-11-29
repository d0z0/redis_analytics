require 'redis'
require 'browser'
require 'geoip'
require 'chartkick'

require 'redis_analytics'

require 'redis_analytics/version'
require 'redis_analytics/time_ext'
require 'redis_analytics/filter'
require 'redis_analytics/configuration'
require 'redis_analytics/metrics'
require 'redis_analytics/visit'
require 'redis_analytics/helpers'
require 'redis_analytics/tracker'
require 'redis_analytics/engine'

module RedisAnalytics
  extend Configuration
end

require 'rails'
require 'jquery-rails'

module RedisAnalytics
  class Engine < ::Rails::Engine
    isolate_namespace RedisAnalytics
  end
end

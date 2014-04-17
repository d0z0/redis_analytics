require 'rails'
require 'jquery-rails'

module RedisAnalytics
  module Dashboard
  class Engine < ::Rails::Engine
    isolate_namespace RedisAnalytics
    
    initializer "redis_analytics.middleware" do |app|
      app.config.app_middleware.use "RedisAnalytics::Tracker"
    end
    
    initializer "redis_analytics.view_helpers" do |app|
      ActionController::Base.send :include, RedisAnalytics::Helpers
    end
  end
  end
end

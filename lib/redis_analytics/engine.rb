require 'rails'
require 'jquery-rails'

module RedisAnalytics
  module Dashboard
    class Engine < ::Rails::Engine
      isolate_namespace RedisAnalytics

      initializer "redis_analytics.middleware" do |app|
        app.config.app_middleware.use "RedisAnalytics::Tracker"
      end

      initializer "redis_analytics.precompile.hook", group: :all do |app|
        app.config.assets.precompile += %w[
          redis_analytics/redis_analytics.js
          redis_analytics/redis_analytics.css
        ]
      end
    end
  end
end

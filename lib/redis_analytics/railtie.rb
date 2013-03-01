module Rack
  module RedisAnalytics
    class Railtie < Rails::Railtie
      initializer "redis_analytics.middleware" do |app|
        app.config.middleware.use "Rack::RedisAnalytics::Mapper"
      end
      
      initializer "redis_analytics.view_helpers" do
        ActionController::Base.send :include, Rack::RedisAnalytics::Helpers
      end
    end
  end
end

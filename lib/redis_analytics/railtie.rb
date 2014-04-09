module RedisAnalytics
  class Railtie < Rails::Railtie
    initializer "redis_analytics.middleware" do |app|
      app.config.middleware.use "RedisAnalytics::Tracker"
    end
    
    initializer "redis_analytics.view_helpers" do
      ActionController::Base.send :include, RedisAnalytics::Helpers
    end
  end
end


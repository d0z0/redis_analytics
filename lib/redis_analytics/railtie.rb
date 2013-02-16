module RedisAnalytics
  class Railtie < Rails::Railtie
    initializer "redis_analytics.insert_middleware" do |app|
      app.config.middleware.use "Rack::RedisAnalytics::Analytics"
    end
  end
end

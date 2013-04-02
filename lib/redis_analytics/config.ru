require 'rack'
require 'sinatra'
require ::File.expand_path("dashboard.rb", File.dirname(__FILE__))

Rack::RedisAnalytics.configure do |c|
  c.redis_connection = Redis.new
end

run Rack::RedisAnalytics::Dashboard


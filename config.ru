$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'redis_analytics'
Rack::RedisAnalytics.configure do |c|
  c.redis_connection = Redis.new

  # known endpoints (filtered by default)
  #c.dashboard_endpoint = '/analytics/dashboard'
  #c.api_endpoint = '/analytics/api'

  c.add_path_filter(/^\/favicon.ico$/)
end

app = Rack::Builder.app do
  use Rack::RedisAnalytics::Tracker
  run Proc.new { |env| [200, {'Content-Type' => 'text/html'}, "You have been tracked!"] }
end
run app

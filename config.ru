$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'redis_analytics'
RedisAnalytics.configure do |c|
  c.redis_connection = Redis.new
  c.add_path_filter(/^\/favicon.ico$/)
end

app = Rack::Builder.app do
  use RedisAnalytics::Tracker
  run Proc.new { |env| [200, {'Content-Type' => 'text/html'}, "You have been tracked!"] }
end
run app

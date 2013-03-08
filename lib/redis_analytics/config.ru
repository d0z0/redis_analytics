require 'rack'
require 'sinatra'
require ::File.expand_path("dashboard.rb", File.dirname(__FILE__))
run Rack::RedisAnalytics::Dashboard
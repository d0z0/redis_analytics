module Rack
  module RedisAnalytics
    class Dashboard < Sinatra::Base
      
      set :static, true
      set :public_folder, ::File.expand_path('..', __FILE__)

      get '/' do
        erb :index
      end
      
    end
  end
end

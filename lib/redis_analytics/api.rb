require 'sinatra/base'

module Rack
  module RedisAnalytics
    
    class Api < Sinatra::Base
      helpers Rack::RedisAnalytics::Helpers
      
      get '/visits/?' do
        result = []
        content_type :json
        
        to_date_time = Date.parse(params[:to_date_time]).to_time rescue Time.now
        unit = params[:unit] || 'day' # minute hour day month year (week not yet supported, but we should do something)
        units = (params[:unit_count] || 1).to_i
        metric = params[:metric] || 'visits' # visits unique_visits bounces unique_bounces, etc
        from_date_time = to_date_time - units.send(unit)
        
        result = self.send("#{unit}ly_#{metric}", from_date_time, :to_date => to_date_time)
        result.to_json
      end
    end
  end
end

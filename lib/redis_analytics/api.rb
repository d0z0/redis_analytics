require 'sinatra/base'

module Rack
  module RedisAnalytics

    class Api < Sinatra::Base
      helpers Rack::RedisAnalytics::Helpers

      get '/data/?' do

        begin
          to_date_time = Date.parse(params[:to_date_time]).to_time rescue Time.now
          unit = params[:unit] || 'day'
          aggregate = (params[:aggregate] == 'yes')
          units = (params[:unit_count] || 1).to_i
          from_date_time = to_date_time - units.send(unit)
          results = []

          metrics = case params[:metrics].class
            when String then params[:metrics].split(',')
            when Array  then params[:metrics]
            else DATA_TYPES # Rack::RedisAnalytics::Helpers::DATA_TYPES
          end

          metrics.each_with_index do |metric, j|
            result = self.send("#{unit}ly_#{metric}", from_date_time, :to_date => to_date_time, :aggregate => aggregate)
            if result.is_a?(Array) # time range data (non-aggregate)
              result.each_with_index do |r, i|
                results[i] ||= {}
                date_value = r[0][0..2]
                time_value = r[0][3..-1]
                date_time_value = []
                date_time_value << date_value.join('-')
                date_time_value << time_value.join(':') if time_value
                results[i]['raw'] = date_time_value.join(' ')
                results[i]['unix'] = Time.mktime(*r[0].map(&:to_i)).to_i
                results[i][metric] = r[1]
              end
            elsif result.is_a?(Hash) or result.is_a?(Fixnum) # aggregate data
              results[j] = {metric => result}
            end
          end
          content_type :json
          results.to_json
        rescue Exception => e
          halt 500, [500, [e.message, e.backtrace]].to_json
        end
      end
    end
  end
end

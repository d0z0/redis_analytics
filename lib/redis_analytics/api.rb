require 'sinatra/base'

module Rack
  module RedisAnalytics

    class Api < Sinatra::Base
      helpers Rack::RedisAnalytics::Helpers

      get '/data/?' do
        result = []
        content_type :json
        begin
          to_date_time = Date.parse(params[:to_date_time]).to_time rescue Time.now
          unit = params[:unit] || 'day'
          aggregate = (params[:aggregate] == 'yes')
          units = (params[:unit_count] || 1).to_i
          metrics = params[:metrics].split(',')
          from_date_time = to_date_time - units.send(unit)
          results = []
          metrics.each do |metric|
            result = self.send("#{unit}ly_#{metric}", from_date_time, :to_date => to_date_time, :aggregate => aggregate)
            result.each_with_index do |r, i|
              results[i] ||= {}

              if !aggregate
                # fetch the date and time
                date_value = r[0][0..2]
                time_value = r[0][3..-1]
                date_time_value = []
                date_time_value << date_value.join('-')
                date_time_value << time_value.join(':') if time_value

                results[i]['raw'] = date_time_value.join(' ')
                results[i]['unix'] = Time.mktime(*r[0].map(&:to_i)).to_i
                results[i][metric] = r[1]
              else
                results[i]['label'] = r[0]
                results[i]['value'] = r[1]
              end

            end
          end
          results.to_json
        rescue Exception => e
          halt 500, [500, [e.message, e.backtrace]].to_json
        end
      end
    end
  end
end

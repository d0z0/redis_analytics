require 'json'

  module RedisAnalytics

    class Api < Sinatra::Base
      helpers RedisAnalytics::Helpers

      get '/data/?' do

        begin
          to_date_time = Date.parse(params[:to_date_time]).to_time rescue Time.now
          unit = params[:unit] || 'day'
          aggregate = (params[:aggregate] == 'yes')
          units = (params[:unit_count] || 1).to_i
          p = params[:p].split(',')
          from_date_time = to_date_time - units.send(unit)
          results = []

          p.each_with_index do |q, j|
            result = self.send("#{unit}ly_#{q}", from_date_time, :to_date => to_date_time, :aggregate => aggregate)
            if result.is_a?(Array) # time range data (non-aggregate)
              result.each_with_index do |r, i|
                results[i] ||= {}
                date_value = r[0][0..2]
                time_value = r[0][3..-1]
                date_time_value = []
                date_time_value << date_value.join('-')
                date_time_value << time_value.join(':') if time_value
                # results[i]['raw'] = date_time_value.join(' ').strip
                results[i]['unix'] = Time.mktime(*r[0].map(&:to_i)).to_i
                strf = case unit
                       when 'minute'
                         '%H%Mhrs'
                       when 'hour'
                         '%a %H00hrs'
                       when 'day'
                         '%a'
                       when 'month'
                         '%b'
                       when 'year'
                         '%Y'
                       end
                results[i]['raw'] = Time.at(results[i]['unix']).strftime(strf)
                results[i][q] = r[1]
              end
            elsif result.is_a?(Hash) or result.is_a?(Fixnum) # aggregate data
              results[j] = {q => result}
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


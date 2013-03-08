require 'sinatra/base'
require 'date'
require 'json'
require 'erb'
require 'active_support/core_ext'
require 'redis_analytics'

Rack::RedisAnalytics.configure do |c|
  c.redis_connection = Redis.new
end

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

module Rack
  module RedisAnalytics
    class Dashboard < Sinatra::Base
      
      dir = ::File.dirname(::File.expand_path(__FILE__))
      
      set :views,  "#{dir}/dashboard/views"
      
      if respond_to? :public_folder
        set :public_folder, "#{dir}/dashboard/public"
      else
        set :public, "#{dir}/dashboard/public"
      end
      
      helpers do
        include Rack::RedisAnalytics::Helpers
      end
      
      set :static, true

      def initialize
        $template_prefix = '/dashboard' if defined? Rails
        super
      end

      get '/' do
        # MONTH
        month_visits = daily_visits(Time.now - 1.month)
        month_new_visits = daily_new_visits(Time.now - 1.month)
        @month_visits_and_new_visits = month_new_visits.inject(Hash[month_visits]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k, 'new_visits' => v[0].to_i, 'returning_visits' => v[1].to_i - v[0].to_i}}

        @total_month_visits = month_visits.inject(0){|s, x| s += x[1].to_i; s}
        @total_month_new_visits = month_new_visits.inject(0){|s, x| s += x[1].to_i; s}
        @month_visits_and_new_visits_donut = [{'label' => 'Returning Visitors', 'value' => @total_month_visits - @total_month_new_visits}, {'label' => 'New Visitors', 'value' => @total_month_new_visits}]

        # WEEK
        week_visits = daily_visits(Time.now - 1.week)
        week_new_visits = daily_new_visits(Time.now - 1.week)
        week_unique_visits = daily_unique_visits(Time.now - 2.weeks + 1.day).map{|x,y| [x.strftime('%a'), y]}
        @week_unique_visits = week_unique_visits[0..6].inject(Hash[week_unique_visits[7..13]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'day_of_week'=> k, 'unique_visits_last' => v[0].to_i, 'unique_visits_this' => v[1].to_i}}
        @week_visits_and_new_visits = week_new_visits.inject(Hash[week_visits]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k, 'new_visits' => v[0].to_i, 'returning_visits' => v[1].to_i - v[0].to_i}}

        @total_week_visits = week_visits.inject(0){|s, x| s += x[1].to_i; s}
        @total_week_new_visits = week_new_visits.inject(0){|s, x| s += x[1].to_i; s}
        @week_visits_and_new_visits_donut = [{'label' => 'Returning Visitors', 'value' => @total_week_visits - @total_week_new_visits}, {'label' => 'New Visitors', 'value' => @total_week_new_visits}]

        # DAY
        day_visits = daily_visits(Time.now - 1.day)
        day_new_visits = daily_new_visits(Time.now - 1.day)
        @day_visits_and_new_visits = day_new_visits.inject(Hash[day_visits]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k, 'new_visits' => v[0].to_i, 'returning_visits' => v[1].to_i - v[0].to_i}}

        @total_day_visits = day_visits.inject(0){|s, x| s += x[1].to_i; s}
        @total_day_new_visits = day_new_visits.inject(0){|s, x| s += x[1].to_i; s}
        @day_visits_and_new_visits_donut = [{'label' => 'Returning\nVisitors', 'value' => @total_day_visits - @total_day_new_visits}, {'label' => 'New\nVisitors', 'value' => @total_day_new_visits}]

        erb :index
      end

    end
  end
end

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
        @range = (request.cookies["_rarng"] || RedisAnalytics.default_range).to_sym # should first try to fetch from cookie what the default range is
        
        t0 = Time.now
        @data = {}
        @data[:year] ||= {}
        @data[:year][:visits] = monthly_visits(t0 - 1.year + 1.month)
        @data[:year][:total_visits] = @data[:year][:visits].inject(0){|s, x| s += x[1].to_i; s}
        @data[:year][:new_visits] = monthly_new_visits(t0 - 1.year + 1.month)
        @data[:year][:total_new_visits] = @data[:year][:new_visits].inject(0){|s, x| s += x[1].to_i; s}
        @data[:year][:page_views] = monthly_page_views(t0 - 1.year + 1.month)
        @data[:year][:total_page_views] = @data[:year][:page_views].inject(0){|s, x| s += x[1].to_i; s}
        @data[:year][:visit_time] = monthly_visit_time(t0 - 1.year + 1.month)
        @data[:year][:avg_visit_time] = Hash[@data[:year][:visit_time]].values.sum.to_f/@data[:year][:visit_time].length.to_f

        @data[:year][:visits_new_visits_plot] = @data[:year][:new_visits].inject(Hash[@data[:year][:visits]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k.strftime('%b'), 'new_visits' => v[0].to_i, 'returning_visits' => v[1].to_i - v[0].to_i}}
        @data[:year][:visits_new_visits_donut] = [{'label' => 'Returning Visitors', 'value' => @data[:year][:total_visits] - @data[:year][:total_new_visits]}, {'label' => 'New Visitors', 'value' => @data[:year][:total_visits]}]

        @data[:year][:browsers_donut] = monthly_ratio_browsers(t0 - 1.year + 1.month, :aggregate => true).map{|x| {'label' => x[0], 'value' => x[1].to_i}}

        year_unique_visits = monthly_unique_visits(t0 - 2.years + 1.month).map{|x,y| [x.strftime('%b'), y]}
        @data[:year][:unique_visits] = year_unique_visits[0..11].inject(Hash[year_unique_visits[12..23]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'unit'=> k, 'unique_visits_last' => v[0].to_i, 'unique_visits_this' => v[1].to_i}}
        year_second_page_views = monthly_second_page_views(t0 - 1.year + 1.month)
        @data[:year][:total_second_page_views] = year_second_page_views.inject(0){|s, x| s += x[1].to_i; s}

        visitor_recency = hourly_ratio_recency(t0 - 1.day + 1.hour, :aggregate => true)
        @data[:year][:visitor_recency_slices] = [0, RedisAnalytics.visitor_recency_slices, '*'].flatten.each_cons(2).inject([]) do |h, (x, y)|
          h << [[x, y], visitor_recency.select{|a, b| a.to_i >= x and (a.to_i < y  or y == '*') }.map{|p, q| q}.sum]
        end


        # WEEK
        @data[:week] ||= {}
        @data[:week][:visits] = daily_visits(t0 - 1.week + 1.day)
        @data[:week][:visits_plot] = @data[:week][:visits].map{|x| {'date' => x[0].strftime('%a'), 'visits' => x[1].to_i}}
        @data[:week][:total_visits] = @data[:week][:visits].inject(0){|s, x| s += x[1].to_i; s}
        @data[:week][:new_visits] = daily_new_visits(t0 - 1.week + 1.day)
        @data[:week][:total_new_visits] = @data[:week][:new_visits].inject(0){|s, x| s += x[1].to_i; s}
        @data[:week][:page_views] = daily_page_views(t0 - 1.week + 1.day)
        @data[:week][:page_views_plot] = @data[:week][:page_views].map{|x| {'date' => x[0].strftime('%a'), 'page_views' => x[1].to_i}}
        @data[:week][:total_page_views] = @data[:week][:page_views].inject(0){|s, x| s += x[1].to_i; s}
        @data[:week][:visit_time] = daily_visit_time(t0 - 1.week + 1.day)
        @data[:week][:avg_visit_time] = Hash[@data[:week][:visit_time]].values.sum.to_f/@data[:week][:visit_time].length.to_f

        @data[:week][:visits_page_views_plot] = @data[:week][:page_views].inject(Hash[@data[:week][:visits]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k.strftime('%a'), 'page_views' => v[0].to_i, 'visits' => v[1].to_i}}

        @data[:week][:visits_new_visits_plot] = @data[:week][:new_visits].inject(Hash[@data[:week][:visits]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k.strftime('%a'), 'new_visits' => v[0].to_i, 'returning_visits' => v[1].to_i - v[0].to_i}}
        @data[:week][:visits_new_visits_donut] = [{'label' => 'Returning Visitors', 'value' => @data[:week][:total_visits] - @data[:week][:total_new_visits]}, {'label' => 'New Visitors', 'value' => @data[:week][:total_new_visits]}]

        @data[:week][:browsers_donut] = daily_ratio_browsers(t0 - 1.week + 1.day, :aggregate => true).map{|x| {'label' => x[0], 'value' => x[1].to_i}}

        week_unique_visits = daily_unique_visits(t0 - 2.weeks + 1.day).map{|x,y| [x.strftime('%a'), y]}
        @data[:week][:unique_visits] = week_unique_visits[0..6].inject(Hash[week_unique_visits[7..13]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'unit'=> k, 'unique_visits_last' => v[0].to_i, 'unique_visits_this' => v[1].to_i}}
        week_second_page_views = daily_second_page_views(t0 - 1.week + 1.day)
        @data[:week][:total_second_page_views] = week_second_page_views.inject(0){|s, x| s += x[1].to_i; s}

        visitor_recency = daily_ratio_recency(t0 - 1.week + 1.day, :aggregate => true)
        @data[:week][:visitor_recency_slices] = [0, RedisAnalytics.visitor_recency_slices, '*'].flatten.each_cons(2).inject([]) do |h, (x, y)|
          h << [[x, y], visitor_recency.select{|a, b| a.to_i >= x and (a.to_i < y  or y == '*') }.map{|p, q| q}.sum]
        end

        # DAY

        @data[:day] ||= {}
        @data[:day][:visits] = hourly_visits(t0 - 1.day + 1.hour)
        @data[:day][:visits_plot] = @data[:day][:visits].map{|x| {'date' => x[0].strftime('%l %P'), 'visits' => x[1].to_i}}
        @data[:day][:total_visits] = @data[:day][:visits].inject(0){|s, x| s += x[1].to_i; s}
        @data[:day][:new_visits] = hourly_new_visits(t0 - 1.day + 1.hour)
        @data[:day][:total_new_visits] = @data[:day][:new_visits].inject(0){|s, x| s += x[1].to_i; s}
        @data[:day][:page_views] = hourly_page_views(t0 - 1.day + 1.hour)
        @data[:day][:page_views_plot] = @data[:day][:page_views].map{|x| {'date' => x[0].strftime('%l %P'), 'page_views' => x[1].to_i}}
        @data[:day][:total_page_views] = @data[:day][:page_views].inject(0){|s, x| s += x[1].to_i; s}
        @data[:day][:visit_time] = hourly_visit_time(t0 - 1.day + 1.hour)
        @data[:day][:avg_visit_time] = Hash[@data[:day][:visit_time]].values.sum.to_f/@data[:day][:visit_time].length.to_f

        @data[:day][:visits_page_views_plot] = @data[:day][:page_views].inject(Hash[@data[:day][:visits]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k.strftime('%l %P'), 'page_views' => v[0].to_i, 'visits' => v[1].to_i}}

        @data[:day][:visits_new_visits_plot] = @data[:day][:new_visits].inject(Hash[@data[:day][:visits]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k.strftime('%l %P'), 'new_visits' => v[0].to_i, 'returning_visits' => v[1].to_i - v[0].to_i}}
        @data[:day][:visits_new_visits_donut] = [{'label' => 'Returning Visitors', 'value' => @data[:day][:total_visits] - @data[:day][:total_new_visits]}, {'label' => 'New Visitors', 'value' => @data[:day][:total_new_visits]}]

        @data[:day][:browsers_donut] = hourly_ratio_browsers(t0 - 1.day + 1.hour, :aggregate => true).map{|x| {'label' => x[0], 'value' => x[1].to_i}}

        day_unique_visits = hourly_unique_visits(t0 - 2.days + 1.hour).map{|x,y| [x.strftime('%l %P'), y]}
        @data[:day][:unique_visits] = day_unique_visits[0..23].inject(Hash[day_unique_visits[24..47]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'unit'=> k, 'unique_visits_last' => v[0].to_i, 'unique_visits_this' => v[1].to_i}}

        day_second_page_views = hourly_second_page_views(t0 - 1.day + 1.hour)
        @data[:day][:total_second_page_views] = day_second_page_views.inject(0){|s, x| s += x[1].to_i; s}

        visitor_recency = hourly_ratio_recency(t0 - 1.day + 1.hour, :aggregate => true)
        @data[:day][:visitor_recency_slices] = [0, RedisAnalytics.visitor_recency_slices, '*'].flatten.each_cons(2).inject([]) do |h, (x, y)|
          h << [[x, y], visitor_recency.select{|a, b| a.to_i >= x and (a.to_i < y  or y == '*') }.map{|p, q| q}.sum]
        end

        t1 = Time.now
        @t = t1 - t0
        erb :index
      end

    end
  end
end

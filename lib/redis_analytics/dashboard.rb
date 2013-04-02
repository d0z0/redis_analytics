require 'sinatra/base'
require 'json'
require 'active_support/core_ext'
require 'redis_analytics'

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

module Rack
  module RedisAnalytics
    class Dashboard < Sinatra::Base
      
      dir = ::File.expand_path(::File.dirname(__FILE__))
      
      set :views,  "#{dir}/dashboard/views"
      
      if respond_to? :public_folder
        set :public_folder, "#{dir}/dashboard/public"
      else
        set :public, "#{dir}/dashboard/public"
      end
      
      helpers do
        include Rack::RedisAnalytics::Helpers
        
        def parse_float(float)
          float.nan? ? '0.0' : float
        end
        
        def with_benchmarking
          @t0 = Time.now
          yield
          @t1 = Time.now
          @t = @t1 - @t0
        end

      end
      
      set :static, true

      def initialize
        $template_prefix = '/dashboard' if defined? Rails
        super
      end

      get '/' do
        status, headers, body = call env.merge("PATH_INFO" => '/visits')
        [status, headers, body]
      end

      get '/activity' do
        with_benchmarking do 
          # code
        end
        erb :activity
      end

      get '/visits' do
        with_benchmarking do
          @range = (request.cookies["_rarng"] || RedisAnalytics.default_range).to_sym # should first try to fetch from cookie what the default range is
          @data = {}
          
          RedisAnalytics.time_range_formats.each do |range, unit, time_format|
            multiple = (1.send(range)/1.send(unit)).round
            time_range = @t0 - 1.send(range) + 1.send(unit)
            @data[range] ||= {}
            @data[range][:visits] = self.send("#{unit}ly_visits".to_sym, time_range)
            @data[range][:total_visits] = @data[range][:visits].inject(0){|s, x| s += x[1].to_i; s}
            @data[range][:new_visits] = self.send("#{unit}ly_new_visits", time_range)
            @data[range][:total_new_visits] = @data[range][:new_visits].inject(0){|s, x| s += x[1].to_i; s}            
            @data[range][:page_views] = self.send("#{unit}ly_page_views", time_range)

            @data[range][:total_page_views] = @data[range][:page_views].inject(0){|s, x| s += x[1].to_i; s}
            @data[range][:visit_time] = self.send("#{unit}ly_visit_time", time_range)
            @data[range][:avg_visit_time] = Hash[@data[range][:visit_time]].values.sum.to_f/@data[range][:visit_time].length.to_f

            @data[range][:visits_new_visits_plot] = @data[range][:new_visits].inject(Hash[@data[range][:visits]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'date'=> k.strftime(time_format), 'new_visits' => v[0].to_i, 'returning_visits' => v[1].to_i - v[0].to_i}}
            @data[range][:visits_new_visits_donut] = [{'label' => 'Returning Visitors', 'value' => @data[range][:total_visits] - @data[range][:total_new_visits]}, {'label' => 'New Visitors', 'value' => @data[range][:total_new_visits]}]

            @data[range][:browsers_donut] = self.send("#{unit}ly_ratio_browsers", time_range, :aggregate => true).map{|x| {'label' => x[0], 'value' => x[1].to_i}}
            @data[range][:platforms_donut] = self.send("#{unit}ly_ratio_platforms", time_range, :aggregate => true).map{|x| {'label' => x[0], 'value' => x[1].to_i}}
            @data[range][:devices_donut] = self.send("#{unit}ly_ratio_platforms", time_range, :aggregate => true).map{|x| {'label' => x[0], 'value' => x[1].to_i}}
            @data[range][:referrers_donut] = self.send("#{unit}ly_ratio_referrers", time_range, :aggregate => true).map{|x| {'label' => x[0], 'value' => x[1].to_i}}

            unique_visits = self.send("#{unit}ly_unique_visits", time_range - 1.send(range)).map{|x,y| [x.strftime(time_format), y]}

            puts unique_visits[0..(multiple-1)].inject(Hash[unique_visits[multiple..(multiple*2-1)]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.inspect
            @data[range][:unique_visits] = unique_visits[0..(multiple-1)].inject(Hash[unique_visits[multiple..(multiple*2-1)]]){|a, i| a[i[0]] = [i[1], a[i[0]]];a}.map{|k,v| {'unit'=> k, 'unique_visits_last' => v[0].to_i, 'unique_visits_this' => v[1].to_i}}
            second_page_views = self.send("#{unit}ly_second_page_views", time_range)
            @data[range][:total_second_page_views] = second_page_views.inject(0){|s, x| s += x[1].to_i; s}
          
            visitor_recency = self.send("#{unit}ly_ratio_recency", time_range, :aggregate => true)
            @data[range][:visitor_recency_slices] = [0, RedisAnalytics.visitor_recency_slices, '*'].flatten.each_cons(2).inject([]) do |h, (x, y)|
              h << [[x, y], visitor_recency.select{|a, b| a.to_i >= x and (a.to_i < y  or y == '*') }.map{|p, q| q}.sum]
            end
            @data[range][:country_map] = Hash[self.send("#{unit}ly_ratio_country", time_range, :aggregate => true)]
          end
          @range = @data.keys[0] unless @data[@range]
        end
        erb :visits
      end
      
    end
  end
end

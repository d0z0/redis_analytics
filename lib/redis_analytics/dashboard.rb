require 'sinatra/base'
require 'sinatra/assetpack'

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

module Rack
  module RedisAnalytics

    class Dashboard < Sinatra::Base
      register Sinatra::AssetPack

      set :root, ::File.expand_path(::File.dirname(__FILE__))
      set :views,  "#{settings.root}/dashboard/views"
      set :static, true

      helpers Rack::RedisAnalytics::Helpers

      assets do
        serve '/css', from: "dashboard/public/css"
        serve '/javascripts', from: "dashboard/public/javascripts"
        serve '/img', from: "dashboard/public/img"
        js :app, [
          '/javascripts/vendor/*.js',
          '/javascripts/*.js'
        ]
        js :bootstrap, [
          '/javascripts/vendor/bootstrap/*.js'
        ]
        css :application, [
          '/css/*.css'
        ]
        js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
        css_compression :simple   # :simple | :sass | :yui | :sqwish
      end

      get '/' do
        redirect url('visits')
      end

      get '/activity/?' do
        with_benchmarking do
          @data = {}
        end
        erb :activity
      end

      get '/visits/?' do
        with_benchmarking do
          @range = time_range
          @data = {}

          RedisAnalytics.time_range_formats.each do |range, unit, time_format|
            multiple = (1.send(range)/1.send(unit)).round
            time_range = @t0 - 1.send(range) + 1.send(unit)

            @data[range] ||= {}
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

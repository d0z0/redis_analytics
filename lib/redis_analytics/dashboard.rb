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
        erb :activity
      end

      get '/visits/?' do
        @range = time_range
        erb :visits
      end

    end
  end
end

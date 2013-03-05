if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end


module Rack
  module RedisAnalytics
    class Dashboard < Sinatra::Base
      
      dir = File.dirname(File.expand_path(__FILE__))
      
      set :views,  "#{dir}/dashboard/views"
      
      if respond_to? :public_folder
        set :public_folder, "#{dir}/server/public"
      else
        set :public, "#{dir}/server/public"
      end
      
      # include Rack::RedisAnalytics::Helpers
      require 'date'
      
      set :static, true

      def initialize
        $template_prefix = '/dashboard' if defined? Rails
        super
      end

      get '/' do
        @dummy = (Date.new(2013,2,28)..Date.today).to_a.map{|x| [x.to_time.to_i * 1000, rand(15)*2+100]}
        @dummy2 = (Date.new(2013,2,28)..Date.today).to_a.map{|x| [x.to_time.to_i * 1000, rand(30)*2]}
        erb :index
      end

    end
  end
end

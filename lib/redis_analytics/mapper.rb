module Rack
  module RedisAnalytics
    class Mapper

      def initialize(app)
        @app = Rack::Builder.new do
          map '/' do
            run Analytics.new(app)
          end
          
          map RedisAnalytics.dashboard_endpoint do
            run Dashboard.new
          end
        end
      end

      def call(env)
        @app.call(env)
      end
      
    end
  end
end


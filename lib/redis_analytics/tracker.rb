module Rack
  module RedisAnalytics
    class Tracker

      def initialize(app)
        @app = Rack::Builder.new do
          map '/' do
            run Analytics.new(app)
          end

          if defined?(Dashboard) and RedisAnalytics.dashboard_endpoint
            map RedisAnalytics.dashboard_endpoint do
              run Dashboard.new
            end
          end
          if defined?(Api) and RedisAnalytics.api_endpoint
            map RedisAnalytics.api_endpoint do
              run Api.new
            end
          end

        end
      end

      def call(env)
        @app.call(env)
      end

    end
  end
end

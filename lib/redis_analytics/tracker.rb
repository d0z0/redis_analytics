  module RedisAnalytics
    class Tracker

      def initialize(app)
        @app = Rack::Builder.new do

          # if defined?(Dashboard) and RedisAnalytics.dashboard_endpoint
          #   puts("WARNING: RedisAnalytics.dashboard_endpoint is set as \"/\"") if RedisAnalytics.dashboard_endpoint == '/'
          #   map RedisAnalytics.dashboard_endpoint do
          #     run Dashboard.new
          #   end
          # end

          map '/' do
            run Analytics.new(app)
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


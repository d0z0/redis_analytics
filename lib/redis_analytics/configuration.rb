module Rack
  module RedisAnalytics
    module Configuration
      # Redis connection instance
      attr_writer :redis_connection

      # Redis namespace for keys
      attr_writer :redis_namespace

      # Name of the cookie which tracks returning visitors (known visitors)
      attr_writer :returning_user_cookie_name

      # Name of the cookie which tracks visits
      attr_writer :visit_cookie_name

      # Minutes the visit should timeout after (if no hit is received)
      attr_writer :visit_timeout

      # Endpoint for dashboard
      attr_writer :dashboard_endpoint

      # Endpoint for api
      attr_writer :api_endpoint

      attr_writer :path_filters

      attr_writer :filters

      # GeoEngine
      attr_writer :geo_engine

      # Path to the Geo IP Database file
      attr_writer :geo_ip_data_path

      # Redis connection instance
      def redis_connection
        @redis_connection ||= Redis.new
      end

      # Redis namespace for keys
      def redis_namespace
        @redis_namespace ||= 'ra'
      end

      # Minutes the visit should timeout after (if no hit is received)
      def visit_timeout
        @visit_timeout ||= 1 # minutes
      end

      # Endpoint for dashboard
      def dashboard_endpoint
        @dashboard_endpoint ||= '/analytics/dashboard'
      end

      # Endpoint for api
      def api_endpoint
        @api_endpoint ||= '/analytics/api'
      end

      # Name of the cookie which tracks returning visitors (known visitors)
      def returning_user_cookie_name
        @returning_user_cookie_name ||= '_rucn'
      end

      # Name of the cookie which tracks visits
      def visit_cookie_name
        @visit_cookie_name ||= '_vcn'
      end

      def filters
        @filters ||= []
      end

      def path_filters
        @path_filters ||= []
      end

      def add_filter(&proc)
        filters << RedisAnalytics::Filter.new(proc)
      end

      def add_path_filter(path)
        path_filters << RedisAnalytics::PathFilter.new(path)
      end

      # Geo tool
      # :geocoder or :geoip (default is: false)
      def geo_engine
        @geo_engine ||= false
      end

      def geo_ip_data_path
        @geo_ip_data_path = ::File.expand_path(::File.join(::File.dirname(__FILE__),'..','..')) + "/bin/GeoIP.dat"
      end

      def visitor_recency_slices
        @visitor_recency_slices ||= [1, 7, 30]
      end

      def default_range
        @default_range = :day
      end

      def redis_key_timestamps # [format, expire in seconds or nil]
        ['%Y', '%Y_%m', '%Y_%m_%d', '%Y_%m_%d_%H', ['%Y_%m_%d_%H_%M', 1.day + 1.minute]]
      end

      def time_range_formats
        [[:year, :month, "%b"], [:week, :day, "%a"], [:day, :hour, "%l%P"]]
      end

      def configure
        yield self
      end

    end
  end
end

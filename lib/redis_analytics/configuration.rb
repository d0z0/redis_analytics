module Rack
  module RedisAnalytics
    module Configuration
      # Redis connection instance
      attr_accessor :redis_connection

      # Redis namespace for keys
      attr_writer :redis_namespace

      # Name of the cookie which tracks first visitors
      attr_writer :first_visit_cookie_name

      # Name of the cookie which tracks current visits
      attr_writer :current_visit_cookie_name

      # Minutes the visit should timeout after (if no hit is received)
      attr_writer :visit_timeout

      # Endpoint for dashboard
      attr_accessor :dashboard_endpoint

      # Endpoint for api
      attr_accessor :api_endpoint

      attr_writer :path_filters

      attr_writer :filters

      # Path to the Geo IP Database file
      attr_writer :geo_ip_data_path

      # Redis namespace for keys
      def redis_namespace
        @redis_namespace ||= 'ra'
      end

      # Minutes the visit should timeout after (if no hit is received)
      def visit_timeout
        @visit_timeout ||= 1 # minutes
      end

      # Name of the cookie which tracks first visitors (unknown visitors)
      def first_visit_cookie_name
        @first_visit_cookie_name ||= '_rucn'
      end

      # Name of the cookie which tracks visits
      def current_visit_cookie_name
        @current_visit_cookie_name ||= '_vcn'
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
        ['%Y', '%Y_%m', '%Y_%m_%d', '%Y_%m_%d_%H', '%Y_%m_%d_%H_%M']
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

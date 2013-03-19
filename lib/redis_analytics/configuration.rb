module Rack
  module RedisAnalytics
    module Configuration
      # Redis connection instance
      attr_accessor :redis_connection
      
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

      # Redis namespace for keys
      attr_writer :geo_ip_data_path

      # Redis namespace for keys
      def redis_namespace
        @redis_namespace ||= 'ra'
      end

      # Minutes the visit should timeout after (if no hit is received)
      def visit_timeout
        @visit_timeout ||= 1 # minutes
      end

      # Name of the cookie which tracks returning visitors (known visitors)
      def returning_user_cookie_name
        @returning_user_cookie_name ||= '_rucn'
      end

      # Name of the cookie which tracks visits
      def visit_cookie_name
        @visit_cookie_name ||= '_vcn'
      end
 
      def dashboard_endpoint
        @dashboard_endpoint ||= '/dashboard'
      end

      def geo_ip_data_path
        @geo_ip_data_path = ::File.expand_path(::File.join(::File.dirname(__FILE__),'..','..'))
      end

      def visitor_recency_slices
        @visitor_recency_slices ||= [1, 7, 30]
      end

      def default_range
        @default_range = :day
      end
     
      def configure
        yield self
      end

    end
  end
end

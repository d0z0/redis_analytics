module Rack
  module RedisAnalytics
    class Geo
      def initialize(args={})
        @args = {
          engine: RedisAnalytics.geo_engine
        }.merge args

        # Fixbug in classify Geoip => GeoIP
        @args[:engine] = case @args[:engine]
          when :geoip, :geo_ip then:geo_i_p
          else @args[:engine]
        end

        @engine = nil
        @geo_data = nil
        load!
      end

      # load engine
      def load!
        engine = case @args[:engine]
          when Symbol then @args[:engine].to_s.classify.constantize
          when String then @args[:engine].classify.constantize
          else nil
        end

        @engine = engine if defined?(engine)
      end

      def defined?
        !!@engine
      end

      # Get geo data
      def get_data(query)
        return nil unless self.defined?

        begin
          @geo_data = case @engine
            when Geocoder
              @engine.search(query).first.data
            when GeoIP
              g = @engine.new(RedisAnalytics.geo_ip_data_path)
              g.country(query)#.to_hash[:country_code2]
            else
              nil
          end
        rescue Exception => e
          puts "Warning: Unable to fetch geographic info #{e}"
        end
        @geo_data
      end
    end
  end
end

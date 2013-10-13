module Rack
  module RedisAnalytics
    module Parameters

      attr_reader :track_visit_time_count
      attr_reader :track_visits_count, :track_new_visits_count, :track_returning_visits_count
      attr_reader :track_unique_visits_types

      # Developers can override the public methods here OR even introduce new
      # Should the private methods be protected?
      # Everything here will be tracked if you call the method called track
      # Tracking differs based on return type of your meth
      # String => ZINCRBY(meth, 1, return_value)
      # Fixnum => INCRBY(meth, return_value)
      # If you return nil or an error nothing will be tracked

      def track_page_views_count
        return 1
      end

      def track_second_page_views_count
        return 1 if @last_visit_start_time == @last_visit_end_time
      end

      def track_browser_types
        browser.name.to_s
      end

      def track_platform_types
        browser.platform.to_s
      end

      def track_country_types
        if defined?(GeoIP)
          begin
            g = GeoIP.new(RedisAnalytics.geo_ip_data_path)
            geo_country_code = g.country(@request.ip).to_hash[:country_code2]
            if geo_country_code and geo_country_code =~ /^[A-Z]{2}$/
              return geo_country_code
            end
          rescue Exception => e
            warn "Unable to fetch country info #{e}"
          end
        end
      end

      def track_recency_count
        # tracking for visitor recency
        if @last_visit_end_time
          days_since_last_visit = ((@t.to_i - @last_visit_end_time.to_i)/(24*3600)).round
          return days_since_last_visit
        end
      end

      # def track_visit_time_count
      #   return (@t.to_i - @last_visit_end_time.to_i)
      # end

      def track_referrer_types
        if @request.referrer
          REFERRERS.each do |referrer|
            # this will track x.google.mysite.com as google so its buggy, fix the regex
            if m = @request.referrer.match(/^(https?:\/\/)?([a-zA-Z0-9\.\-]+\.)?(#{referrer})\.([a-zA-Z\.]+)(:[0-9]+)?(\/.*)?$/)
              "REFERRER => #{m.to_a[3]}"
              referrer = m.to_a[3]
            else
              referrer = 'other'
            end
          end
        else
          referrer = 'organic'
        end
        return referrer
      end

      private
      def browser
        Browser.new(:ua => @request.user_agent, :accept_language => 'en-us')
      end

    end
  end
end

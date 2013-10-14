module Rack
  module RedisAnalytics
    module Parameters

      attr_reader :visit_time_count_per_visit
      attr_reader :visits_count_per_visit, :first_visits_count_per_visit, :repeat_visits_count_per_visit
      attr_reader :unique_visits_datum_per_visit
      attr_reader :page_views_count_per_hit, :second_page_views_count_per_hit

      # Developers can override or define new public methods here
      # Methods should start with track and end with count or types
      # Return types should be Fixnum or String resp.
      # If you return nil or an error nothing will be tracked

      def browser_datum_per_visit
        user_agent.name.to_s
      end

      def platform_datum_per_visit
        user_agent.platform.to_s
      end

      def country_datum_per_visit
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

      def recency_count_per_visit
        # tracking for visitor recency
        if @last_visit_end_time
          days_since_last_visit = ((@t.to_i - @last_visit_end_time.to_i)/(24*3600)).round
          return days_since_last_visit
        end
      end

      def device_datum_per_visit
        return ((user_agent.mobile? or user_agent.tablet?) ? 'mobile' : 'desktop')
      end

      def referrer_datum_per_visit
        if @request.referrer
          ['google', 'bing', 'yahoo', 'cleartrip', 'github'].each do |referrer|
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
      def user_agent
        Browser.new(:ua => @request.user_agent, :accept_language => 'en-us')
      end

    end
  end
end

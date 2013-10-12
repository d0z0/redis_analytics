# -*- coding: utf-8 -*-
require 'digest/md5'
module Rack
  module RedisAnalytics
    class Analytics

      REFERRERS = ['google', 'bing', 'yahoo', 'cleartrip', 'github']

      def initialize(app)
        @app = app
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        @env = env
        @request  = Request.new(env)
        status, headers, body = @app.call(env)
        @response = Rack::Response.new(body, status, headers)
        record if should_record?
        @response.finish
      end

      def should_record?
        return false unless @response.ok?
        return false unless @response.content_type =~ /^text\/html/
        RedisAnalytics.path_filters.each do |filter|
          return false if filter.matches?(@request.path)
        end
        RedisAnalytics.filters.each do |filter|
          return false if filter.matches?(@request, @response)
        end
        return true
      end

      def record
        v = Visit.new(@request, @response)
        v.record
        @response.set_cookie(RedisAnalytics.current_visit_cookie_name, v.updated_current_visit_info)
        @response.set_cookie(RedisAnalytics.first_visit_cookie_name, v.updated_first_visit_info)
      end

      def visit(t, options = {})
        last_visit_time = options[:last_visit_time] || nil
        rucn_seq = options[:rucn_seq] || nil
        geo_country_code = nil
        referrer = nil
        ua = nil

        # Geo IP Country code fetch
        if defined?(GeoIP)
          begin
            g = GeoIP.new(RedisAnalytics.geo_ip_data_path)
            geo_country_code = g.country(@request.ip).to_hash[:country_code2]
          rescue Exception => e
            puts "Warning: Unable to fetch country info #{e}"
          end
        end

        # Referrer regex decode
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

        # User agent
        ua = Browser.new(:ua => @request.user_agent, :accept_language => 'en-us')
        browser = "#{ua.name} #{ua.version}"

        for_each_time_range(t) do |ts, expire|

          # increment the total visits
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits:#{ts}")
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}visits:#{ts}", expire) if expire

          if rucn_seq
            unique = RedisAnalytics.redis_connection.sadd("#{@redis_key_prefix}unique_visits:#{ts}", rucn_seq)
            RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}unique_visits:#{ts}", expire) if expire

            # Unique detailed desktop and mobile/tablet list.
            if ua.mobile? || ua.tablet?
              RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}unqiue_mobile_browser_info:#{ts}", 1, browser)
              RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}unqiue_mobile_browser_info:#{ts}", expire) if expire
            else
              RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}unqiue_desktop_browser_info:#{ts}", 1, browser)
              RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}unqiue_desktop_browser_info:#{ts}", expire) if expire
            end          

            # geo ip tracking
            if geo_country_code and geo_country_code =~ /^[A-Z]{2}$/
              RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_country:#{ts}", 1, geo_country_code)
              RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}ratio_country:#{ts}", expire) if expire
            end

            # referrer tracking 
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_referrers:#{ts}", 1, referrer)
          end

          # tracking for visitor recency
          if last_visit_time
            days_since_last_visit = ((t.to_i - last_visit_time)/(24*3600)).round
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_recency:#{ts}", 1, days_since_last_visit)
            RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}ratio_recency:#{ts}", expire) if expire
          end

          # Total detailed desktop and mobile/tablet list.
          if ua.mobile? || ua.tablet?
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}total_mobile_browser_info:#{ts}", 1, browser)
            RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}total_mobile_browser_info:#{ts}", expire) if expire
          else
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}total_desktop_browser_info:#{ts}", 1, browser)
            RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}total_desktop_browser_info:#{ts}", expire) if expire
          end

          RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_browsers:#{ts}", 1,  ua.name)
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}ratio_browsers:#{ts}", expire) if expire

          RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_platforms:#{ts}", 1, ua.platform.to_s)
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}ratio_platforms:#{ts}", expire) if expire

          RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_devices:#{ts}", 1, ua.mobile? ? 'M' : 'D')
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}ratio_devices:#{ts}", expire) if expire
        end
      end

      def visit_time(t, visit_end_time = nil)
        for_each_time_range(t) do |ts, expire|
          RedisAnalytics.redis_connection.incrby("#{@redis_key_prefix}visit_time:#{ts}", t.to_i - visit_end_time)
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}visit_time:#{ts}", expire) if expire
        end
      end

      # 2nd pageview in a visit
      def page_view(t, second_page_view = false)
        for_each_time_range(t) do |ts, expire|
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}page_views:#{ts}")
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}page_views:#{ts}", expire) if expire

          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}second_page_views:#{ts}") if second_page_view
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}second_page_views:#{ts}", expire) if second_page_view and expire
        end
      end

    end
  end
end

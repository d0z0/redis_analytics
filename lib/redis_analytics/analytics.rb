# -*- coding: utf-8 -*-
require 'digest/md5'
module Rack
  module RedisAnalytics
    
    class Analytics
      
      PAGEVIEWS = [['/health', 'o', 'd', 't'], ['/track', 'o', 'd', 't']]

      TRANSACTIONS = {
        "flights_search" => ["/flights/search", :o, :d],
        "flights_results" => ["/flights/results", :o, :d],
        "flights_book_step_1" => ["/flights/itinerary/:itinerary_id/info"],
        "flights_book_step_2" => ["/flights/itinerary/:itinerary_id/traveller"],
        "flights_book_step_3" => ["/flights/itinerary/:itinerary_id/pay"],
        "flights_book_done" => ["/flights/itinerary/:itinerary_id/confirmation"],
        "products" => ["/products/:id/review", :user_id]
      }

      REFERRERS = ['google', 'bing', 'yahoo', 'cleartrip']

      def initialize(app)
        @app = app
        @redis_key_prefix = "#{RedisAnalytics.redis_namespace}:"
      end
      
      # def call(env)
      #   dup.call!(env)
      # end

      def call(env)
        @env = env
        @request  = Request.new(env)
        status, headers, body = @app.call(env)
        @response = Rack::Response.new(body, status, headers)
        record if @response.ok? and @response.content_type =~ /^text\/html/
        @response.finish
      end

      def parse_path(path)
        keys = []
        spc = %w{. + ( )}
        pattern =
          path.to_str.gsub(/((:\w+)|[\*#{spc.join}])/) do |match|
          case match
          # when "*"
          #   keys << 'splat'
          #   "(.*?)"
          when *spc
            Regexp.escape(match)
          else
            keys << $2[1..-1]
            "([^/?&#]+)"
          end
        end
        [/^#{pattern}$/, keys]
      end

      def for_each_time_range(t)
        RedisAnalytics.redis_key_timestamps.map{|x, y| [t.strftime(x), y]}.each do |ts, expire|
          yield(ts, expire) # returns an array of the redis methods to call 
          # r.each do |method, args|
          #   RedisAnalytics.redis_connection.send(method, *args)
          #   RedisAnalytics.redis_connection.expire(args[1]) if expire # assuming args[1] is always the key that is being operated on.. will this always work?
          # end
        end
      end

      def record
        t = Time.now 

        # record pageviews
        path = @request.path
        params = @request.params
        if i = PAGEVIEWS.index{|x| x[0] == path}
          page = PAGEVIEWS[i]
          params.select{|x, y| page[1..-1].include?(x)}.each do |k, v|
            for_each_time_range(t) do |ts, expire|
              h = Digest::MD5.hexdigest(v)
              RedisAnalytics.redis_connection.hset("#{@redis_key_prefix}page", h, v)
              RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}page", expire) if expire

              RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}page_#{i}_#{page.index(k)}_#{h}:#{ts}")
              RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}page_#{i}_#{page.index(k)}_#{h}:#{ts}", expire) if expire
            end
          end
        end
        
        returning_visitor = @request.cookies[RedisAnalytics.returning_user_cookie_name]
        recent_visitor = @request.cookies[RedisAnalytics.visit_cookie_name]

        vcn_seq, rucn_seq = nil
        visit_start_time =visit_end_time = first_visit_time = t.to_i

        if not returning_visitor and not recent_visitor
          rucn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}unique_visits")
          vcn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits")
          visit(t, :rucn_seq => rucn_seq)
          new_visit(t)
          visit_time(t, t.to_i)
          page_view(t)
        elsif returning_visitor and not recent_visitor
          vcn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits")
          rucn_seq, first_visit_time, last_visit_time = returning_visitor.split('.')
          visit(t, :last_visit_time => last_visit_time.to_i, :rucn_seq => rucn_seq)
          page_view(t)
        elsif returning_visitor and recent_visitor
          rucn_seq, vcn_seq, visit_start_time, visit_end_time = recent_visitor.split('.')
          rucn_seq, first_visit_time = returning_visitor.split('.')
          visit_time(t, visit_end_time.to_i)
          page_view(t, visit_start_time.to_i == visit_end_time.to_i)
        elsif not returning_visitor and recent_visitor
          rucn_seq, vcn_seq, visit_start_time, visit_end_time = recent_visitor.split('.')
          visit_time(t, visit_end_time.to_i)
          page_view(t, visit_start_time.to_i == visit_end_time.to_i)
        end

        # create the recent visit cookie
        @response.set_cookie(RedisAnalytics.visit_cookie_name, {:value => "#{rucn_seq}.#{vcn_seq}.#{visit_start_time}.#{t.to_i}", :expires => t + (RedisAnalytics.visit_timeout.to_i * 60 )})

        # create the permanent cookie (2 years)
        @response.set_cookie(RedisAnalytics.returning_user_cookie_name, {:value => "#{rucn_seq}.#{first_visit_time}.#{t.to_i}", :expires => t + (60 * 60 * 24 * 5)}) # 5 hours temp

        puts "TIME = [#{t}]"
        puts "VISIT = #{vcn_seq}"
        puts "UNIQUE VISIT = #{rucn_seq}"
      end
      
      def new_visit(t)
        for_each_time_range(t) do |ts, expire|
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}new_visits:#{ts}")
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}new_visits:#{ts}",expire) if expire
        end
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
            puts "Tracking IP #{@request.ip} using #{g.inspect} => GOT #{geo_country_code}"
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
        
        for_each_time_range(t) do |ts, expire|

          # increment the total visits
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits:#{ts}")
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}visits:#{ts}", expire) if expire

          if rucn_seq
            unique = RedisAnalytics.redis_connection.sadd("#{@redis_key_prefix}unique_visits:#{ts}", rucn_seq)
            RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}unique_visits:#{ts}", expire) if expire
            
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
          puts "PAGEVIEW ++ @ #{ts}"
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}page_views:#{ts}")
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}page_views:#{ts}", expire) if expire

          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}second_page_views:#{ts}") if second_page_view
          RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}second_page_views:#{ts}", expire) if second_page_view and expire
        end
      end


    end
  end
end

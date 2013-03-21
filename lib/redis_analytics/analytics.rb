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


      # METRIC KEYS (constructed exactly in reports)
      # format -> [prefix|domain-index|metric|timestamp]
      # 
      # available metrics:
      # 
      # visits
      # new_visits
      # unique_visits
      # visit_time
      # ratio_browsers
      # ratio_platforms
      # ratio_devices
      # page_A_B_MD5 (A => url-index, B => parameter-index, MD5 => value-key)

      # PAGEVIEWS (used in reports for labeling transactions)
      # format -> [prefix|domain-index|page][md5(value)] = value
      #

      def initialize(app)
        @app = app
        @redis_key_prefix = "#{RedisAnalytics.redis_namespace}:"
      end
      
      def call(env)
        record_visits(env)
      end
      
      def record_visits(env)
        t0 = Time.now 
        @request = Rack::Request.new(env)
        # call the @app
        status, headers, body = @app.call(env)
        
        # create a response
        @response = Rack::Response.new(body, status, headers)
        
        t = Time.now 
        # record pageviews
        path = @request.path
        params = @request.params
        if i = PAGEVIEWS.index{|x| x[0] == path}
          page = PAGEVIEWS[i]
          params.select{|x, y| page[1..-1].include?(x)}.each do |k, v|
            [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
              h = Digest::MD5.hexdigest(v)
              RedisAnalytics.redis_connection.hset("#{@redis_key_prefix}page", h, v)
              RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}page_#{i}_#{page.index(k)}_#{h}:#{ts}")
            end
          end
        end
        
        # record visits
        # if returning_visitor = @request.cookies[RedisAnalytics.returning_user_cookie_name]
        #   # RETURNING VISITOR (NEW OR SAME VISIT)
        #   rucn_seq, first_visit_time = returning_visitor.split('.')
        #   record_recent_visitor(t, rucn_seq, first_visit_time)
        # else
        #   unless record_recent_visitor(t)
        #     # FIRST TIME VISITOR
        #     [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
        #       RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}new_visits:#{ts}")
        #     end
        #   end
        # end

        # new code

        returning_visitor = @request.cookies[RedisAnalytics.returning_user_cookie_name]
        recent_visitor = @request.cookies[RedisAnalytics.visit_cookie_name]

        vcn_seq, rucn_seq = nil

        visit_start_time =visit_end_time = first_visit_time = t.to_i

        if not returning_visitor and not recent_visitor
          rucn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}unique_visits")
          vcn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits")
          new_visit(t)
          visit(t, :rucn_seq => rucn_seq)
          visit_time(t, t.to_i)
          page_view(t)
          # new visit
          # rucn_seq ++ and push to unique
          # visits ++
          # visit_time ++
          # page_view ++
        elsif returning_visitor and not recent_visitor
          vcn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits")
          rucn_seq, first_visit_time, last_visit_time = returning_visitor.split('.')
          visit(t, :last_visit_time => last_visit_time.to_i, :rucn_seq => rucn_seq)
          page_view(t)
          # get rucn_seq and push to unique
          # visits ++
        elsif returning_visitor and recent_visitor
          rucn_seq, vcn_seq, visit_start_time, visit_end_time = recent_visitor.split('.')
          rucn_seq, first_visit_time = returning_visitor.split('.')
          visit_time(t, visit_end_time.to_i)
          page_view(t, visit_start_time.to_i == visit_end_time.to_i)
          # visit_time ++
          # page_view ++
        elsif not returning_visitor and recent_visitor
          rucn_seq, vcn_seq, visit_start_time, visit_end_time = recent_visitor.split('.')
          visit_time(t, visit_end_time.to_i)
          page_view(t, visit_start_time.to_i == visit_end_time.to_i)
          # get rucn_seq from vcn and push to unique
          # visit_time ++
          # page_view ++
        end

        # create the recent visit cookie
        @response.set_cookie(RedisAnalytics.visit_cookie_name, {:value => "#{rucn_seq}.#{vcn_seq}.#{visit_start_time}.#{t.to_i}", :expires => t + (RedisAnalytics.visit_timeout.to_i * 60 )})

        # create the permanent cookie (2 years)
        @response.set_cookie(RedisAnalytics.returning_user_cookie_name, {:value => "#{rucn_seq}.#{first_visit_time}.#{t.to_i}", :expires => t + (60 * 60 * 24 * 5)}) # 5 hours temp

        puts "TIME = [#{t}]"
        puts "VISIT = #{vcn_seq}"
        puts "UNIQUE VISIT = #{rucn_seq}"

        # write the response
        @response.finish
      end
      
      def new_visit(t)
        [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}new_visits:#{ts}")
        end
      end
      
      def visit(t, options = {})
        last_visit_time = options[:last_visit_time] || nil
        rucn_seq = options[:rucn_seq] || nil
        
        [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|

          # increment the total visits
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits:#{ts}")

          if rucn_seq
            unique = RedisAnalytics.redis_connection.sadd("#{@redis_key_prefix}unique_visits:#{ts}", rucn_seq)
            puts "UNIQUE => #{unique}" 
            if unique and defined?(GeoIP)
              begin
                g = GeoIP.new("#{RedisAnalytics.geo_ip_data_path}/GeoIP.dat")
                geo_country_code = g.country("115.111.79.34").to_hash[:country_code2]
                RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_country:#{ts}", 1, geo_country_code)
              rescue
                puts "Warning: Unable to fetch country info"
              end
            end
          end
          
          # tracking for visitor recency
          if last_visit_time
            days_since_last_visit = ((t.to_i - last_visit_time)/(24*3600)).round
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_recency:#{ts}", 1, days_since_last_visit)
          end

          # add ua info
          ua = Browser.new(:ua => @request.user_agent, :accept_language => 'en-us')
          RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_browsers:#{ts}", 1,  ua.name)
          RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_platforms:#{ts}", 1, ua.platform.to_s)
          RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_devices:#{ts}", 1, ua.mobile? ? 'M' : 'D')

        end        
      end

      def visit_time(t, visit_end_time = nil)
        [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
          RedisAnalytics.redis_connection.incrby("#{@redis_key_prefix}visit_time:#{ts}", t.to_i - visit_end_time)
        end
      end

      # 2nd pageview in a visit
      def page_view(t, second_page_view = false)
        [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}page_views:#{ts}")
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}second_page_views:#{ts}") if second_page_view
        end
      end


    end
  end
end

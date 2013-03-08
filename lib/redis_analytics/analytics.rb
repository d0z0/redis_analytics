# -*- coding: utf-8 -*-
require 'digest/md5'
module Rack
  module RedisAnalytics
    
    class Analytics
      
      PAGEVIEWS = [['/health', 'o', 'd', 't'], ['/track', 'o', 'd', 't']]


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
          rucn_seq= RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}unique_visits")
          vcn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits")
          new_visit(t)
          unique_visit(t, rucn_seq)
          visit(t)
          visit_time(t, t.to_i)
          # new visit
          # rucn_seq ++ and push to unique
          # visits ++
          # update visit time
        elsif returning_visitor and not recent_visitor
          vcn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits")
          rucn_seq, first_visit_time = returning_visitor.split('.')
          unique_visit(t, rucn_seq)
          visit(t)
          # get rucn_seq and push to unique
          # visits ++
        elsif returning_visitor and recent_visitor
          rucn_seq, vcn_seq, visit_start_time, visit_end_time = recent_visitor.split('.')
          rucn_seq, first_visit_time = returning_visitor.split('.')
          visit_time(t, visit_end_time.to_i)
          # visit_time ++
        elsif not returning_visitor and recent_visitor
          rucn_seq, vcn_seq, visit_start_time, visit_end_time = recent_visitor.split('.')
          unique_visit(t, rucn_seq)
          visit_time(t, visit_end_time.to_i)
          # get rucn_seq from vcn and push to unique
          # visit_time ++
        end

        # create the recent visit cookie
        @response.set_cookie(RedisAnalytics.visit_cookie_name, {:value => "#{rucn_seq}.#{vcn_seq}.#{visit_start_time}.#{t.to_i}", :expires => t + (RedisAnalytics.visit_timeout.to_i * 60 )})

        # create the permanent cookie (2 years)
        @response.set_cookie(RedisAnalytics.returning_user_cookie_name, {:value => "#{rucn_seq}.#{first_visit_time}.#{t.to_i}", :expires => t + (2 * 365 * 24 * 60 * 60)})

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
      
      def unique_visit(t, rucn_seq)
        [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
          RedisAnalytics.redis_connection.sadd("#{@redis_key_prefix}unique_visits:#{ts}", rucn_seq)
        end
      end

      def visit(t)
        [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|

          # increment the total visits
          RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits:#{ts}")

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

      def record_recent_visitor(t, rucn_seq = nil, first_visit_time = nil)
        visit_start_time, visit_end_time = t.to_i
        first_visit_time ||= t.to_i

        if recent_visitor = @request.cookies[RedisAnalytics.visit_cookie_name]
          # SAME VISIT
          rucn_seq, vcn_seq, visit_start_time, visit_end_time = recent_visitor.split('.')
          # add to total visit time
          [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
            RedisAnalytics.redis_connection.incrby("#{@redis_key_prefix}visit_time:#{ts}", t.to_i - visit_end_time.to_i)
          end
        else
          # NEW VISIT FROM RETURNING VISITOR
          vcn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits")
          rucn_seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}unique_visits")
          
          [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
            # increment the total visits
            RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits:#{ts}")
            
            # add to total unique visits
            RedisAnalytics.redis_connection.sadd("#{@redis_key_prefix}unique_visits:#{ts}", rucn_seq)
            
            # add ua info
            ua = Browser.new(:ua => @request.user_agent, :accept_language => 'en-us')
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_browsers:#{ts}", 1,  ua.name)
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_platforms:#{ts}", 1, ua.platform.to_s)
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_devices:#{ts}", 1, ua.mobile? ? 'M' : 'D')
          end
        end
        # simply update the visit_start_time and visit_end_time


        # create the recent visit cookie
        @response.set_cookie(RedisAnalytics.visit_cookie_name, {:value => "#{rucn_seq}.#{vcn_seq}.#{visit_start_time}.#{t.to_i}", :expires => t + (RedisAnalytics.visit_timeout.to_i * 60 )})

        # create the permanent cookie (2 years)
        @response.set_cookie(RedisAnalytics.returning_user_cookie_name, {:value => "#{rucn_seq}.#{first_visit_time}.#{t.to_i}", :expires => t + (24 * 60 * 60)})

        puts "TIME = [#{t}]"
        puts "VISIT = #{vcn_seq}"
        puts "UNIQUE VISIT = #{rucn_seq}"

        # return the sequencer
        recent_visitor
      end

    end
  end
end

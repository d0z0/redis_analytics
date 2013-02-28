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
            # RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}x:#{i}_#{v}_:#{t.strftime('%Y_%m_%d_%H_%M')}")
            # RedisAnalytics.redis_connection.expire("#{@redis_key_prefix}x:#{i}_#{v}_:#{t.strftime('%Y_%m_%d_%H_%M')}", 60*60)
          end
          
        end

        # record visits
        if visit = @request.cookies[RedisAnalytics.returning_user_cookie_name]
          track_recent_visit(t)
        else
          unless track_recent_visit(t)
            [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
              RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}new_visits:#{ts}")
            end
          end
        end

        # write the response
        @response.finish
      end
      
      def track_recent_visit(t)
        visit_start_time, visit_end_time = t.to_i
        if recent_visit = @request.cookies[RedisAnalytics.visit_cookie_name]
          # recent visit was made
          seq, visit_start_time, visit_end_time = recent_visit.split('.')
          # add to total visit time
          [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
            RedisAnalytics.redis_connection.incrby("#{@redis_key_prefix}visit_time:#{ts}", t.to_i - visit_end_time.to_i)
          end
        else
          # no recent visit
          [t.strftime('%Y'), t.strftime('%Y_%m'), t.strftime('%Y_%m_%d'), t.strftime('%Y_%m_%d_%H')].each do |ts|
            # increment the total visits
            seq = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}visits:#{ts}")
            # add to total unique visits
            RedisAnalytics.redis_connection.sadd("#{@redis_key_prefix}unique_visits:#{ts}", seq)

            # add ua info
            ua = Browser.new(:ua => @request.user_agent, :accept_language => 'en-us')
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_browsers:#{ts}", 1,  ua.name)
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_platforms:#{ts}", 1, ua.platform.to_s)
            RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}ratio_devices:#{ts}", 1, ua.mobile? ? 'M' : 'D')
          end
        end
        # simply update the visit_start_time and visit_end_time
        @response.set_cookie(RedisAnalytics.visit_cookie_name, {:value => "#{seq}.#{visit_start_time}.#{t.to_i}", :expires => t + (RedisAnalytics.visit_timeout.to_i * 60 )})

        # create the permanent cookie (2 years)
        @response.set_cookie(RedisAnalytics.returning_user_cookie_name, {:value => "RedisAnalytics - copyright Schubert Cardozo - 2013 - http://www.github.com/saturnine/redis_analytics", :expires => t + (2 * 365 * 24 * 60 * 60)})

        puts "VISIT = #{seq} [#{t}]"

        # return the sequencer
        recent_visit
      end
      
    end
  end
end

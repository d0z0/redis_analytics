module Rack
  module RedisAnalytics
    class Analytics
      
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
        @response = Rack::Response.new body, status, headers
        
        t = Time.now
        if visit = @request.cookies[RedisAnalytics.returning_user_cookie_name]
          track_recent_visit(t)
        else
          unless track_recent_visit(t)
            [t.strftime("%Y"), t.strftime("%Y_%m"), t.strftime("%Y_%m_%d"), t.strftime("%Y_%m_%d_%H")].each do |ts|
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
          [t.strftime("%Y"), t.strftime("%Y_%m"), t.strftime("%Y_%m_%d"), t.strftime("%Y_%m_%d_%H")].each do |ts|
            RedisAnalytics.redis_connection.incrby("#{@redis_key_prefix}visit_time:#{ts}", t.to_i - visit_end_time.to_i)
          end
        else
          # no recent visit
          [t.strftime("%Y"), t.strftime("%Y_%m"), t.strftime("%Y_%m_%d"), t.strftime("%Y_%m_%d_%H")].each do |ts|
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

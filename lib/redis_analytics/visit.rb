module Rack
  module RedisAnalytics
    class Visit
      include Parameters

      # This class represents one unique visit
      # User may have never visited the site
      # User may have visited before but his visit is expired
      # Everything counted here is unique for a visit

      # helpers

      def for_each_time_range(t)
        RedisAnalytics.redis_key_timestamps.map{|x, y| t.strftime(x)}.each do |ts|
          yield(ts)
        end
      end

      def first_visit_info
        cookie = @request.cookies[RedisAnalytics.first_visit_cookie_name]
        return cookie ? cookie.split('.') : []
      end

      def current_visit_info
        cookie = @request.cookies[RedisAnalytics.current_visit_cookie_name]
        return cookie ? cookie.split('.') : []
      end

      # method used in analytics.rb to initialize visit

      def initialize(request, response)
        @t = Time.now
        @redis_key_prefix = "#{RedisAnalytics.redis_namespace}:"
        @request = request
        @response = response
        @first_visit_seq = first_visit_info[0] || current_visit_info[0]
        @current_visit_seq = current_visit_info[1]

        @first_visit_time = first_visit_info[1]
        @last_visit_time = first_visit_info[2]

        @last_visit_start_time = current_visit_info[2]
        @last_visit_end_time = current_visit_info[3]
      end

      # called from analytics.rb

      def record
        if @current_visit_seq
          track("visit_time", @t.to_i - @last_visit_end_time.to_i)
        else
          @current_visit_seq ||= counter("visits")

          track("visits")
          if @first_visit_seq
            track("returning_visits")
          else
            @first_visit_seq ||= counter("unique_visits")
            track("new_visits")
            track("unique_visits", @first_visit_seq)
          end
          Parameters.public_instance_methods.grep(/^track_/) do |meth|
            return_value = self.send(meth)
            track(meth[6..-1], return_value)
          end
        end
        track("page_views")
        track("second_page_views") if @last_visit_start_time == @last_visit_end_time
      end

      # helpers
      def counter(parameter_name)
        #RedisAnalytics.redis_connection.sadd("#{@redis_key_prefix}#PARAMETERS", parameter_name)
        RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}#{parameter_name}")
      end

      def updated_current_visit_info
        value = [@first_visit_seq, @current_visit_seq, (@last_visit_start_time || @t).to_i, @t.to_i]
        expires = @t + (RedisAnalytics.visit_timeout.to_i * 60)
        {:value => value.join('.'), :expires => expires}
      end

      def updated_first_visit_info
        value = [@first_visit_seq, (@first_visit_time || @t).to_i, @t.to_i]
        expires = @t + (60 * 60 * 24 * 5) # 5 hours
        {:value => value.join('.'), :expires => expires}
      end

      def track(parameter_name, parameter_value = nil)
        RedisAnalytics.redis_connection.hmset("#{@redis_key_prefix}#PARAMETERS", parameter_name, parameter_value.class)
        for_each_time_range(@t) do |ts|
          if parameter_value
            if parameter_value.is_a?(Fixnum)
              puts "INCRBY #{parameter_name}#{ts} #{parameter_value}"
              RedisAnalytics.redis_connection.incrby("#{@redis_key_prefix}#{parameter_name}:#{ts}", parameter_value)
            else
              puts "ZINCRBY #{parameter_name}#{ts} 1 #{parameter_value}"
              RedisAnalytics.redis_connection.zincrby("#{@redis_key_prefix}#{parameter_name}:#{ts}", 1, parameter_value)
            end
          else
            puts "INCR #{parameter_name}#{ts}"
            RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}#{parameter_name}:#{ts}")
          end
        end
      end

    end
  end
end

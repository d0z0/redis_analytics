  module RedisAnalytics
    class Visit
      include Metrics

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
        cookie = @rack_request.cookies[RedisAnalytics.first_visit_cookie_name]
        return cookie ? cookie.split('.') : []
      end

      def current_visit_info
        cookie = @rack_request.cookies[RedisAnalytics.current_visit_cookie_name]
        return cookie ? cookie.split('.') : []
      end

      # method used in analytics.rb to initialize visit
      def initialize(request, response)
        @t = Time.now
        @redis_key_prefix = "#{RedisAnalytics.redis_namespace}:"
        @rack_request = request
        @rack_response = response
        @first_visit_seq = first_visit_info[0] || current_visit_info[0]
        @current_visit_seq = current_visit_info[1]

        @first_visit_time = first_visit_info[1]
        @last_visit_time = first_visit_info[2]

        @page_view_seq_no = current_visit_info[2] || 0
        @last_visit_start_time = current_visit_info[3]
        @last_visit_end_time = current_visit_info[4]
      end

      # called from analytics.rb
      def record
        if @current_visit_seq
          track("visit_time", @t.to_i - @last_visit_end_time.to_i)
        else
          @current_visit_seq ||= counter("visits")
          track("visits", 1) # track core 'visit' metric
          if @first_visit_seq
            track("repeat_visits", 1)
          else
            @first_visit_seq ||= counter("unique_visits")
            track("first_visits", 1)
            track("unique_visits", @first_visit_seq)
          end
          exec_custom_methods('visit') # custom methods that are measured on a per-visit basis
        end
        exec_custom_methods('hit') # custom methods that are measured on a per-page-view (per-hit) basis
        track("page_views", 1) # track core 'page_view' metric
        track("second_page_views", 1) if @page_view_seq_no.to_i == 1 # @last_visit_start_time and (@last_visit_start_time.to_i == @last_visit_end_time.to_i)
        @rack_response
      end

      def exec_custom_methods(type)
        Metrics.public_instance_methods.each do |meth|
          if m = meth.to_s.match(/^([a-z_]*)_(count|ratio)_per_#{type}$/)
            begin
              return_value = self.send(meth)
              track(m.to_a[1], return_value) if return_value
            rescue => e
              warn "#{meth} resulted in an exception #{e}"
            end
          end
        end
      end

      # helpers
      def counter(metric_name)
        n = RedisAnalytics.redis_connection.incr("#{@redis_key_prefix}#{metric_name}")
        # to debug, uncomment this line
        # puts "COUNT #{metric_name} -> #{n}"
        return n
      end

      def updated_current_visit_info
        value = [@first_visit_seq.to_i, @current_visit_seq.to_i, @page_view_seq_no.to_i + 1, (@last_visit_start_time || @t).to_i, @t.to_i]
        # to debug, uncomment this line
        # puts "UPDATING VCN COOKIE -> #{value}"
        expires = @t + (RedisAnalytics.visit_timeout.to_i * 60)
        {:value => value.join('.'), :expires => expires}
      end

      def updated_first_visit_info
        value = [@first_visit_seq.to_i, (@first_visit_time || @t).to_i, @t.to_i]
        # to debug, uncomment this line
        # puts "UPDATING RUCN COOKIE -> #{value}"
        expires = @t + (60 * 60 * 24 * 5) # 5 hours
        {:value => value.join('.'), :expires => expires}
      end

      def track(metric_name, metric_value)
        n = 0
        RedisAnalytics.redis_connection.hmset("#{@redis_key_prefix}#METRICS", metric_name, metric_value.class)
        for_each_time_range(@t) do |ts|
          key = "#{@redis_key_prefix}#{metric_name}:#{ts}"
          if metric_value.is_a?(Fixnum)
            n = RedisAnalytics.redis_connection.incrby(key, metric_value)
          else
            n = RedisAnalytics.redis_connection.zincrby(key, 1, metric_value)
          end
        end
        # to debug, uncomment this line
        # puts "TRACK #{metric_name} -> #{n}" 
        return n
      end

    end
  end


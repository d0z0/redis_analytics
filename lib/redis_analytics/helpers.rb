module Rack
  module RedisAnalytics
    module Helpers
      
      private
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /^(hour|dai|month|year)ly_(new_visits|visits|unique_visits|visit_time)$/
          granularity = $1 + 'ly'
          type = $2
          data(granularity, type, *args)
        else
          super
        end
      end

      FS = [['%Y', 356], ['%m', 30], ['%d', 24], ['%H', 60 * 60]]
      GR = ['yearly', 'monthly', 'daily', 'hourly']

      def data(granularity, type, from_date, to_date = Time.now)
        seq = RedisAnalytics.incr("#{RedisAnalytics.redis_namespace}#SEQUENCER")
        union_key = "#{RedisAnalytics.redis_namespace}#UNION##{key}##{seq}"
        i = from_date
        union = []
        while i < to_date
          i += FS[GR.index(granularity)..-1].map{|x| x[1]}.inject{|p,x| p*=x; p}
          union << "#{RedisAnalytics.redis_namespace}#{i.strftime(FS[0..GR.index(granularity)].map{|x| x[0]}.join('_'))}"
        end
        union
        RedisAnalytics.redis_connection.zunionstore(union_key, union) 
        RedisAnalytics.redis_connection.expire(union_key, 5 * 60) 
      end
      
      # helpers for platform/browser
      def browsers(time = nil)
        Rack::RedisAnalytics.redis_connection.zrange("#{RedisAnalytics.redis_namespace}UA_B_#{t.strftimex}", 0, -1, :with_scores => true)
      end
      
      # def browser_versions(time = nil)
      #   Rack::RedisAnalytics.redis_connection.zrange("#{RedisAnalytics.redis_namespace}UA_B_V_#{t.strftime}", 0, -1, :with_scores => true)
      # end

      def os_platforms(time = nil)
        Rack::RedisAnalytics.redis_connection.zrange("#{RedisAnalytics.redis_namespace}UA_OS_#{t.strftime}", 0, -1, :with_scores => true)
      end

      def devices(time = nil)
        Rack::RedisAnalytics.redis_connection.zrange("#{RedisAnalytics.redis_namespace}UA_D_#{t.strftime}", 0, -1, :with_scores => true)
      end

      # helpers for visits
      def total_visits(time = nil)
        
      end

      def total_new_visits(time = nil)
        
      end

      def total_unqiue_visits(time = nil)
        
      end

      def average_time_on_site(time = nil)
        
      end

      def bounce_rate(time = nil)
        
      end

      def activity
        
      end

    end
  end
end

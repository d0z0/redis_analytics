module Rack
  module RedisAnalytics
    module Helpers

      FORMAT_SPECIFIER = [['%Y', 356], ['%m', 30], ['%d', 24], ['%H', 60 * 60]]
      GRANULARITY = ['yearly', 'monthly', 'daily', 'hourly']

      # all methods are private unless explicitly declared public
      private
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /^(hour|dai|month|year)ly_(new_visits|visits|unique_visits|visit_time|ratio_browsers|ratio_platforms|ratio_devices)$/
          granularity = $1 + 'ly'
          type = $2
          data(granularity, type, *args)
        else
          super
        end
      end

      def data(granularity, type, from_date, to_date = Time.now)
        i = from_date
        union = []
        begin
          union << "#{Rack::RedisAnalytics.redis_namespace}:#{type}:#{i.strftime(FORMAT_SPECIFIER[0..GRANULARITY.index(granularity)].map{|x| x[0]}.join('_'))}"
          i += FORMAT_SPECIFIER[GRANULARITY.index(granularity)..-1].map{|x| x[1]}.inject{|p,x| p*=x; p}
        end while i <= to_date
        puts union.inspect
        if type =~ /unique/
          Rack::RedisAnalytics.redis_connection.sunion(*union).length
        elsif type =~ /ratio/
          seq = get_next_seq
          union_key = "#{Rack::RedisAnalytics.redis_namespace}:#{seq}"
          Rack::RedisAnalytics.redis_connection.zunionstore(union_key, union)
          Rack::RedisAnalytics.redis_connection.expire(union_key, 100)
          Rack::RedisAnalytics.redis_connection.zrange(union_key, 0, -1, :with_scores => true)
        else
          Rack::RedisAnalytics.redis_connection.mget(*union).inject(0){|s, x| s += x.to_i; s}
        end
      end
      
      def get_next_seq
        seq = Rack::RedisAnalytics.redis_connection.incr("#{Rack::RedisAnalytics.redis_namespace}:#SEQUENCER")
      end

    end
  end
end

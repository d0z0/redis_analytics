require 'rubygems'
require 'active_support'

module TimeExtensions
  %w[ round floor ceil ].each do |_method|
    define_method _method do |*args|
      seconds = args.first || 60
      Time.at((self.to_f / seconds).send(_method) * seconds)
    end
  end
end

Time.send :include, TimeExtensions

module Rack
  module RedisAnalytics
    module Helpers

      FORMAT_SPECIFIER = [['%Y', 365], ['%m', 30], ['%d', 24], ['%H', 60], ['%M', 60]]
      GRANULARITY = ['yearly', 'monthly', 'daily', 'hourly', 'minutely']

      # all methods are private unless explicitly declared public
      private
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /^(minute|hour|dai|month|year)ly_(new_visits|visits|page_views|second_page_views|unique_visits|visit_time|ratio_recency|ratio_browsers|ratio_platforms|ratio_devices)$/
          granularity = $1 + 'ly'
          type = $2
          data(granularity, type, *args)
        else
          super
        end
      end

      def data(granularity, type, from_date, options = {})
        aggregate = options[:aggregate] || false
        to_date = (options[:to_date] || Time.now).ceil(60*60) - 30.minutes
        i = from_date.ceil(60*60)  - 30.minutes
        union = []
        time = []
        begin
          union << "#{Rack::RedisAnalytics.redis_namespace}:#{type}:#{i.strftime(FORMAT_SPECIFIER[0..GRANULARITY.index(granularity)].map{|x| x[0]}.join('_'))}"
          time << i
          i += FORMAT_SPECIFIER[GRANULARITY.index(granularity)..-1].map{|x| x[1]}.inject{|p,x| p*=x; p}
        end while i <= to_date
        puts "UNION #{union.inspect}"
        seq = get_next_seq
        if type =~ /unique/
          if aggregate
            union_key = "#{Rack::RedisAnalytics.redis_namespace}:#{seq}"
            Rack::RedisAnalytics.redis_connection.sunionstore(union_key, union)
            Rack::RedisAnalytics.redis_connection.expire(union_key, 100)
            return Rack::RedisAnalytics.redis_connection.scard(union_key)
          else
            return time.zip(union.map{|x| Rack::RedisAnalytics.redis_connection.scard(x)})
          end
        elsif type =~ /ratio/
          if aggregate
            union_key = "#{Rack::RedisAnalytics.redis_namespace}:#{seq}"
            Rack::RedisAnalytics.redis_connection.zunionstore(union_key, union)
            Rack::RedisAnalytics.redis_connection.expire(union_key, 100)
            return Rack::RedisAnalytics.redis_connection.zcard(union_key)
          else
            return time.zip(union.map{|x| Rack::RedisAnalytics.redis_connection.zcard(x)})
          end
        else
          time.zip(Rack::RedisAnalytics.redis_connection.mget(*union).map(&:to_i))
        end
      end
      
      def get_next_seq
        seq = Rack::RedisAnalytics.redis_connection.incr("#{Rack::RedisAnalytics.redis_namespace}:#SEQUENCER")
      end

    end
  end
end

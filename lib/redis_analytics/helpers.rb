require 'active_support/core_ext'

module Rack
  module RedisAnalytics
    module Helpers

      FORMAT_SPECIFIER = [['%Y', 365], ['%m', 30], ['%d', 24], ['%H', 60], ['%M', 60]]

      GRANULARITY = ['yearly', 'monthly', 'dayly', 'hourly', 'minutely']

      DATA_TYPES = ['new_visits', 'returning_visits', 'visits', 'page_views', 'second_page_views',
                    'unique_visits', 'visit_time', 'ratio_recency',
                    'ratio_browsers', 'ratio_platforms', 'ratio_devices',
                    'ratio_country', 'ratio_referrers', 'unqiue_mobile_browser_info',
                    'unqiue_desktop_browser_info', 'total_mobile_browser_info',
                    'total_desktop_browser_info']

      private
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /^(minute|hour|dai|day|month|year)ly_(#{DATA_TYPES.join('|')})$/
          granularity = ($1 == 'dai' ? 'day' : $1) + 'ly'
          type = $2
          data(granularity, type, *args)
        else
          super
        end
      end

      def data(granularity, type, from_date, options = {})
        aggregate = options[:aggregate] || false
        x = granularity[0..-3]

        to_date = (options[:to_date] || Time.now).send("end_of_#{x}")
        i = from_date.send("beginning_of_#{x}")

        union = []
        time = []
        begin
          slice_key = i.strftime(FORMAT_SPECIFIER[0..GRANULARITY.index(granularity)].map{|x| x[0]}.join('_'))
          union << "#{RedisAnalytics.redis_namespace}:#{type}:#{slice_key}"
          time << slice_key.split('_')
          i += 1.send(x)
        end while i <= to_date
        puts union.inspect
        seq = get_next_seq
        if type =~ /unique/
          if aggregate
            union_key = "#{RedisAnalytics.redis_namespace}:#{seq}"
            RedisAnalytics.redis_connection.sunionstore(union_key, union)
            RedisAnalytics.redis_connection.expire(union_key, 100)
            return RedisAnalytics.redis_connection.scard(union_key)
          else
            return time.zip(union.map{|x| RedisAnalytics.redis_connection.scard(x)})
          end
        elsif type =~ /ratio/
          if aggregate
            union_key = "#{RedisAnalytics.redis_namespace}:#{seq}"
            RedisAnalytics.redis_connection.zunionstore(union_key, union)
            RedisAnalytics.redis_connection.expire(union_key, 100)
            return Hash[RedisAnalytics.redis_connection.zrange(union_key, 0, -1, :with_scores => true)]
          else
            return time.zip(union.map{|x| Hash[RedisAnalytics.redis_connection.zrange(x,0,-1, :with_scores => true)]})
          end
        else
          if aggregate
            return RedisAnalytics.redis_connection.mget(*union).map(&:to_i).inject(:+)
          else
            return time.zip(RedisAnalytics.redis_connection.mget(*union).map(&:to_i))
          end
        end
      end

      def get_next_seq
        seq = RedisAnalytics.redis_connection.incr("#{RedisAnalytics.redis_namespace}:#SEQUENCER")
      end

      def realistic(n, r = 1000)
        return n
        n + r + rand(r)
      end

      def parse_float(float)
        float.nan? ? '0.0' : float
      end

      def with_benchmarking
        @t0 = Time.now
        yield
        @t1 = Time.now
        @t = @t1 - @t0
        puts "Time Taken: #{@t} seconds"
      end

      def time_range
        # should first try to fetch from cookie what the default range is
        (request.cookies["_rarng"] || RedisAnalytics.default_range).to_sym
      end
    end
  end
end

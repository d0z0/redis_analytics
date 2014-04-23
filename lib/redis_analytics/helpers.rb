module RedisAnalytics
  module Helpers

    FORMAT_SPECIFIER = [['%Y', 365], ['%m', 30], ['%d', 24], ['%H', 60], ['%M', 60]]

    GRANULARITY = ['yearly', 'monthly', 'dayly', 'hourly', 'minutely']

    private
    def method_missing(meth, *args, &block)
      if meth.to_s =~ /^(minute|hour|dai|day|month|year)ly_([a-z_0-9]+)$/
        granularity = ($1 == 'dai' ? 'day' : $1) + 'ly'
        metric_name = $2
        data(granularity, metric_name, *args)
      else
        super
      end
    end

    def metric_type(metric_name)
      RedisAnalytics.redis_connection.hget("#{RedisAnalytics.redis_namespace}:#METRICS", metric_name)
    end

    def data(granularity, metric_name, from_date, options = {})
      aggregate = options[:aggregate] || false
      x = granularity[0..-3]

      to_date = (options[:to_date] || Time.now).send("end_of_#{x}")
      i = from_date.send("beginning_of_#{x}")

      union = []
      time = []
      begin
        slice_key = i.strftime(FORMAT_SPECIFIER[0..GRANULARITY.index(granularity)].map{|x| x[0]}.join('_'))
        union << "#{RedisAnalytics.redis_namespace}:#{metric_name}:#{slice_key}"
        time << slice_key.split('_')
        i += 1.send(x)
      end while i <= to_date
      seq = get_next_seq
      if metric_type(metric_name) == 'String'
        if aggregate
          union_key = "#{RedisAnalytics.redis_namespace}:#{seq}"
          RedisAnalytics.redis_connection.zunionstore(union_key, union)
          RedisAnalytics.redis_connection.expire(union_key, 100)
          return Hash[RedisAnalytics.redis_connection.zrange(union_key, 0, -1, :with_scores => true)]
        else
          return time.zip(union.map{|x| Hash[RedisAnalytics.redis_connection.zrange(x, 0, -1, :with_scores => true)]})
        end
      elsif metric_type(metric_name) == 'Fixnum'
        if aggregate
          return RedisAnalytics.redis_connection.mget(*union).map(&:to_i).inject(:+)
        else
          return time.zip(RedisAnalytics.redis_connection.mget(*union).map(&:to_i))
        end
      else
        if Metrics.public_instance_methods.any?{|m| m.to_s =~ /^#{metric_name}_ratio_per_(hit|visit)$/}
          aggregate ? {} : time.zip([{}] * time.length)
        elsif Metrics.public_instance_methods.any?{|m| m.to_s =~ /^#{metric_name}_count_per_(hit|visit)$/}
          aggregate ? 0 : time.zip([0] * time.length)
        else
          aggregate ? 0 : time.zip([0] * time.length)
        end
      end
    end

    def get_next_seq
      seq = RedisAnalytics.redis_connection.incr("#{RedisAnalytics.redis_namespace}:#SEQUENCER")
    end

    def time_range
      (request.cookies["_rarng"] || RedisAnalytics.default_range).to_sym
    end
  end
end


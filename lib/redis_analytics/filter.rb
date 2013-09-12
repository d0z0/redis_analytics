module Rack
  module RedisAnalytics
    class Filter
      attr_reader :filter_criteria

      def initialize(filter_criteria)
        @filter_criteria = filter_criteria
      end

      def matches?(request_criteria)
        debug "CHECK #{filter_criteria.inspect} AGAINST #{request_criteria}"
        if filter_criteria.is_a?(String)
          request_criteria == filter_criteria
        elsif filter_criteria.is_a?(Regexp)
          request_criteria =~ filter_criteria
        elsif filter_criteria.is_a?(Proc)
          filter_criteria.call(request_criteria)
        end
      end

    end

    class PathFilter < Filter

    end

    class IpFilter < Filter

    end

  end
end

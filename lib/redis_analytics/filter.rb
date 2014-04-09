  module RedisAnalytics
    class Filter
      attr_reader :filter_proc

      def initialize(filter_proc)
        @filter_proc = filter_proc
      end

      def matches?(request, response)
        filter_proc.call(request, response)
      end

    end

    class PathFilter
      attr_reader :filter_path

      def initialize(filter_path)
        @filter_path = filter_path
      end

      def matches?(request_path)
        if filter_path.is_a?(String)
          request_path == filter_path
        elsif filter_path.is_a?(Regexp)
          request_path =~ filter_path
        end
      end
    end

  end


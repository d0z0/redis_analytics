module RedisAnalytics
  class VisitsController < RedisAnalytics::ApplicationController

    def index
      @range = time_range
    end

  end
end

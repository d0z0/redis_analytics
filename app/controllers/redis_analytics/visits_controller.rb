module RedisAnalytics
  class VisitsController < ApplicationController

    def index
      @range = time_range
    end

  end
end

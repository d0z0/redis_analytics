module RedisAnalytics
  class DashboardsController < RedisAnalytics::ApplicationController

    def index
      @range = params[:range] || 'day' #|| last_saved_range
      @range_count = params[:range_count] || 10
    end

  end
end

module RedisAnalytics
  class ApplicationController < ActionController::Base
    def last_saved_range
      (request.cookies["_rarng"] || RedisAnalytics.default_range).to_sym
    end
  end
end

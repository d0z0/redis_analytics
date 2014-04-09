# -*- coding: utf-8 -*-
require 'digest/md5'
module RedisAnalytics
  class Analytics

    def initialize(app)
      @app = app
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @env = env
      @request  = Rack::Request.new(env)
      status, headers, body = @app.call(env)
      @response = Rack::Response.new(body, status, headers)
      record if should_record?
      @response.finish
    end

    def should_record?
      return false unless @response.ok?
      return false unless @response.content_type =~ /^text\/html/
      RedisAnalytics.path_filters.each do |filter|
        return false if filter.matches?(@request.path)
      end
      RedisAnalytics.filters.each do |filter|
        return false if filter.matches?(@request, @response)
      end
      return true
    end

    def record
      v = Visit.new(@request, @response)
      @response = v.record
      @response.set_cookie(RedisAnalytics.current_visit_cookie_name, v.updated_current_visit_info)
      @response.set_cookie(RedisAnalytics.first_visit_cookie_name, v.updated_first_visit_info)
    end

  end
end

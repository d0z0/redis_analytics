require 'spec_helper'

describe Rack::RedisAnalytics::Configuration do

  context 'property redis_connection' do
    subject(:connection) { Rack::RedisAnalytics.redis_connection }
    it 'should not be nil' do
      connection.should_not be_nil
    end
    it 'should be an instance of Redis' do
      connection.instance_of? Redis 
    end
  end

  context 'property redis_namespace' do
    subject(:namespace) { Rack::RedisAnalytics.redis_namespace }
    it 'should not be nil' do
      namespace.should_not be_nil
    end
    it 'should have an default value' do
      namespace.should be == "_ra_test_namespace"
    end
    it 'can be set to another value' do
      namespace = "test_ra"
      namespace.should be == "test_ra"
    end
  end

  context 'property returning_user_cookie_name' do 
    subject(:return_cookie) { Rack::RedisAnalytics.returning_user_cookie_name }
    it 'should not be nil' do
      return_cookie.should_not be_nil
    end
    it 'should have an default value' do 
      return_cookie.should be == "_rucn"
    end
    it 'has an setter method' do 
      return_cookie = "rucn"
      return_cookie.should be == "rucn"
    end
  end

  context 'property visit_cookie_name' do 
    subject(:visit_cookie_name) { Rack::RedisAnalytics.visit_cookie_name }
    it 'should not be nil' do 
      visit_cookie_name.should_not be_nil
    end
    it 'should have an default value' do 
      visit_cookie_name.should be == "_vcn"
    end
    it 'can be set to another value' do
      visit_cookie_name = "test_vcn"
      visit_cookie_name.should be == "test_vcn"
    end
  end

  context 'property visit_timeout' do
    subject(:visit_timeout) { Rack::RedisAnalytics.visit_timeout }
    it 'should not be nil' do 
      visit_timeout.should_not be_nil
    end
    it 'should have an default value' do 
      visit_timeout.should be == 1
    end
    it 'can be set to another value' do 
      visit_timeout = 5
      visit_timeout.should be == 5
    end
  end

  context 'property dashboard_endpoint' do
    subject(:endpoint) { Rack::RedisAnalytics.dashboard_endpoint }
    it 'should not be nil' do 
      endpoint.should_not be_nil
    end
    it 'should have an default value' do
      endpoint.should be == "/dashboard"
    end
    it 'can be set to another value' do
      endpoint = "/testboard"
      endpoint.should be == "/testboard"
    end
  end

  context 'property visitor_recency_slices' do
    subject(:visitor_recency_slices) { Rack::RedisAnalytics.visitor_recency_slices }
    it 'should not be nil' do
      visitor_recency_slices.should_not be_nil
    end
    it 'should be an Array of Fixnum' do 
      visitor_recency_slices.instance_of? Array
      visitor_recency_slices.each do |value|
        value.instance_of? Fixnum
      end
    end
    it 'can not be set to another value' do 
      visitor_recency_slices = 'nothing'
      visitor_recency_slices.should_not == 'nothing'
    end
  end

  context 'property default_range' do 
    subject(:default_range) { Rack::RedisAnalytics.default_range }
    it 'should not be nil' do
      default_range.should_not be_nil
    end
    it 'should have an value'
    it 'should be an symbol'
    it 'cannot be set to another value'
  end

  context 'property redis_key_timestamps' do
    subject(:redis_key_timestamps) { Rack::RedisAnalytics.redis_key_timestamps }
    it 'should not be nil' do
      default_range.should_not be_nil
    end
    it 'should have an value'
    it 'cannot be set to another value'
  end

  context 'property time_range_formats' do
    subject(:time_range_formats) { Rack::RedisAnalytics.time_range_formats }
    it 'should not be nil' do
      time_range_formats.should_not be_nil
    end
    it 'should have an value'
    it 'should be an array'
    it 'cannot be set to another value'
  end

end
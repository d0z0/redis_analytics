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

  context 'property first_visit_cookie_name' do 
    subject(:return_cookie) { Rack::RedisAnalytics.first_visit_cookie_name }
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

  context 'property current_visit_cookie_name' do 
    subject(:current_visit_cookie_name) { Rack::RedisAnalytics.current_visit_cookie_name }
    it 'should not be nil' do 
      current_visit_cookie_name.should_not be_nil
    end
    it 'should have an default value' do 
      current_visit_cookie_name.should be == "_vcn"
    end
    it 'can be set to another value' do
      current_visit_cookie_name = "test_vcn"
      current_visit_cookie_name.should be == "test_vcn"
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
    it 'can be set to another value' do 
      visitor_recency_slices = [3, 7, 9]
      expect(visitor_recency_slices).to eq([3, 7, 9])
    end
  end

  context 'property default_range' do 
    subject(:default_range) { Rack::RedisAnalytics.default_range }
    it 'should not be nil' do
      default_range.should_not be_nil
    end
    it 'should be an symbol' do
      default_range.instance_of? Symbol
    end
    it 'should have an value' do
      default_range.should be == :day
    end
    it 'can be set to another value' do
      default_range = :month
      default_range.should be :month
    end
  end

  context 'property redis_key_timestamps' do
    subject(:redis_key_timestamps) { Rack::RedisAnalytics.redis_key_timestamps }
    it 'should not be nil' do
      redis_key_timestamps.should_not be_nil
    end
    it 'should be an instance of Array' do
      redis_key_timestamps.instance_of? Array
    end
    it 'can be set to another value' do
      redis_key_timestamps = ['one', 'two']
      expect(redis_key_timestamps).to eq(['one','two'])
    end
  end

  context 'property time_range_formats' do
    subject(:time_range_formats) { Rack::RedisAnalytics.time_range_formats }
    it 'should not be nil' do
      time_range_formats.should_not be_nil
    end
    it 'should be an Array of Array' do
      time_range_formats.instance_of? Array
      time_range_formats.each do |range|
        range.instance_of? Array
      end
    end
    it 'can be set to another value' do
      time_range_formats = "nothing"
      expect(time_range_formats).to eq("nothing")
    end
  end

  context 'method add_filter' do
    subject(:filters) { Rack::RedisAnalytics.filters }
    it 'should add a new filter' do
      proc = Proc.new {}
      Rack::RedisAnalytics.configure do |c|
        c.add_filter(&proc)
      end
      filters[0].should be_an_instance_of Rack::RedisAnalytics::Filter
    end
  end

  context 'method add_path_filter' do
    subject(:path_filters) { Rack::RedisAnalytics.path_filters }
    it 'should add a new path filter' do
      path = '/hello'
      Rack::RedisAnalytics.configure do |c|
        c.add_path_filter(path)
      end
      path_filters[0].should be_an_instance_of Rack::RedisAnalytics::PathFilter
    end
  end

end

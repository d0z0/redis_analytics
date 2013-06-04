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

end
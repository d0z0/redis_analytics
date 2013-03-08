require 'spec_helper'

describe Rack::RedisAnalytics::Analytics do
  include Rack::Test::Methods
  
  def app 
    Rack::Builder.app do
      use Rack::RedisAnalytics::Analytics
      run Proc.new { |env| [200, {}, "Fuck you!"] }
    end
  end

  before(:each) do
    @redis_connection = Rack::RedisAnalytics.redis_connection
    clear_cookies
    # @redis_connection.flushdb
  end

  # Spec for Cookies
  
  context "when a visit has not timed out" do
    it "should count as the same visit" do
      t1 = Time.now
      get '/'
      last_response.original_headers['Set-Cookie'].should =~ /#{Rack::RedisAnalytics.visit_cookie_name}=1.#{t1.to_i}.#{t1.to_i}/
      t2 = t1 + (Rack::RedisAnalytics.visit_timeout * 60) - 1
      Time.stubs(:now).returns(t2)
      get '/'
      last_response.original_headers['Set-Cookie'].should =~ /#{Rack::RedisAnalytics.visit_cookie_name}=1.#{t1.to_i}.#{t2.to_i}/
    end
  end
  
  context "when the visit has timed out" do
    it "should count as the next visit" do
      t1 = Time.now
      get '/'
      last_response.original_headers['Set-Cookie'].should =~ /#{Rack::RedisAnalytics.visit_cookie_name}=1.#{t1.to_i}.#{t1.to_i}/
      clear_cookies
      t2 = Time.now
      get '/'
      last_response.original_headers['Set-Cookie'].should =~ /#{Rack::RedisAnalytics.visit_cookie_name}=2.#{t2.to_i}.#{t2.to_i}/
    end

  end

  it "should track new visits properly" do
    get '/'
    last_response.original_headers['Set-Cookie'].should =~ /#{Rack::RedisAnalytics.returning_user_cookie_name}=/
  end

end

require 'spec_helper'

describe Rack::RedisAnalytics::Analytics do
  include Rack::Test::Methods
  
  def app 
    Rack::Builder.app do
      use Rack::RedisAnalytics::Analytics
      run Proc.new { |env| [200, {'Content-Type' => 'text/html'}, "Hello!"] }
    end
  end

  before(:each) do
    @redis_connection = Rack::RedisAnalytics.redis_connection
    clear_cookies
    # @redis_connection.flushdb
  end

  # Spec for Cookies
  
  context "when a user makes 2 visits and the visit cookie and returning user cookie are not expired" do
    it "it should count as the same visit" do
      t1 = Time.now
      get '/'
      last_response.original_headers['Set-Cookie'].should =~ Regexp.new("#{Rack::RedisAnalytics.visit_cookie_name}=1\.1\.#{t1.to_i}\.#{t1.to_i}")
      last_response.original_headers['Set-Cookie'].should =~ Regexp.new("#{Rack::RedisAnalytics.returning_user_cookie_name}=1\.#{t1.to_i}\.#{t1.to_i}")
      t2 = t1 + 5 # just adding 5 seconds
      Time.stubs(:now).returns(t2)
      get '/'
      last_response.original_headers['Set-Cookie'].should =~ Regexp.new("#{Rack::RedisAnalytics.visit_cookie_name}=1\.1\.#{t1.to_i}\.#{t2.to_i}")
      last_response.original_headers['Set-Cookie'].should =~ Regexp.new("#{Rack::RedisAnalytics.returning_user_cookie_name}=1\.#{t1.to_i}\.#{t2.to_i}")
    end
  end
  
  context "when a user makes 2 visits, but visit cookie and returning user cookie are both non-existent" do
    it "should count as a separate and new visit" do
      t1 = Time.now
      get '/'
      last_response.original_headers['Set-Cookie'].should =~ Regexp.new("#{Rack::RedisAnalytics.visit_cookie_name}=1\.1\.#{t1.to_i}\.#{t1.to_i}")
      last_response.original_headers['Set-Cookie'].should =~ Regexp.new("#{Rack::RedisAnalytics.returning_user_cookie_name}=1\.#{t1.to_i}.#{t1.to_i}")
      clear_cookies
      t2 = Time.now
      get '/'
      last_response.original_headers['Set-Cookie'].should =~ Regexp.new("#{Rack::RedisAnalytics.visit_cookie_name}=2\.2\.#{t1.to_i}\.#{t1.to_i}")
      last_response.original_headers['Set-Cookie'].should =~ Regexp.new("#{Rack::RedisAnalytics.returning_user_cookie_name}=2\.#{t2.to_i}\.#{t2.to_i}")
    end
  end
  context "when a user makes 2 visits, and visit cookie is expired but the returning user cookie exists" do
    it "should count as a separate visit but not a new visit"
  end

end

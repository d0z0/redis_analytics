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
    clear_cookies
  end

  it "should set the tracker for visitor cookie" do
    get '/'
    last_response.original_headers.values.should be_any {|m| m =~ /#{Rack::RedisAnalytics.visit_cookie_name}=/}
  end
  
  it "should set the tracker for returning user cookie" do
    get '/'
    last_response.original_headers.values.should be_any {|m| m =~ /#{Rack::RedisAnalytics.returning_user_cookie_name}=/}
  end
  
end

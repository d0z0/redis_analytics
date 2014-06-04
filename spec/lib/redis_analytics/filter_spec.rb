require 'spec_helper'

describe RedisAnalytics::Filter do

  before do
    @mock_request = Rack::Request.new(:ip => "127.0.0.1", :path => '/ignored')
    @mock_response = Rack::Response.new(:content_type => "text/csv")
  end

  context "when a Filter matches" do
    it "should return true" do
      proc = Proc.new  do |req, res|
        req.ip == @mock_request.ip and res.content_type == @mock_response.content_type
      end
      filter = RedisAnalytics::Filter.new(proc)
      expect(filter.matches?(@mock_request, @mock_response)).to be_true
    end
  end

  context "when a string PathFilter matches" do
    it "should return true" do
      filter = RedisAnalytics::PathFilter.new(@mock_request.path)
      expect(filter.matches?(@mock_request.path)).to be_true
    end
  end

  context "when a regexp PathFilter matches" do
    it "should return true" do
      filter = RedisAnalytics::PathFilter.new(/#{@mock_request.path}/)
      expect(filter.matches?(@mock_request.path)).to be_true
    end
  end

end

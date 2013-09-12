require 'spec_helper'

describe Rack::RedisAnalytics::Dashboard do

  subject(:app) { Rack::RedisAnalytics::Dashboard }

  context 'the pretty dashboard' do

    before do
      Rack::RedisAnalytics.configure do |c|
        c.dashboard_endpoint = '/analytics/dashboard'
      end
    end

    it 'should be mapped to configured endpoint' do
      get Rack::RedisAnalytics.dashboard_endpoint
      last_response.ok?
    end

    it 'should be content-type html' do
      get Rack::RedisAnalytics.dashboard_endpoint
      last_response.headers['Content-Type'] == "text/html"
    end

    it 'should contain the word Visits' do
      get Rack::RedisAnalytics.dashboard_endpoint
      last_response.body.include? "Visits"
    end

  end

end

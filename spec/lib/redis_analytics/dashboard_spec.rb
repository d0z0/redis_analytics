require 'spec_helper'

describe Rack::RedisAnalytics::Dashboard do

  subject(:app) { Rack::RedisAnalytics::Dashboard }

  context 'the pretty dashboard' do

    it 'should redirect to visits' do
      get '/'
      last_response.should be_redirect
      # how do we check the redirect location?
    end

    it 'should be mapped to configured endpoint' do
      get '/'
      last_response.ok?
    end

    it 'should be content-type html' do
      get '/'
      last_response.headers['Content-Type'] == "text/html"
    end

    it 'should contain the word Visits' do
      get '/'
      last_response.body.include? "Visits"
    end

  end

end

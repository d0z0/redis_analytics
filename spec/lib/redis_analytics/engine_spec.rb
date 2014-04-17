require 'spec_helper'

describe RedisAnalytics::Dashboard::Engine do

  subject(:app) { RedisAnalytics::Dashboard::Engine }

  context 'the pretty dashboard' do

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

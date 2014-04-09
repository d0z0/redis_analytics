require 'spec_helper'

describe RedisAnalytics::Tracker do

  subject(:app) {
    Rack::Builder.app do
      use RedisAnalytics::Tracker
      run Proc.new { |env| [200, {'Content-Type' => 'text/html'}, "Hello!"] }
    end
  }

  context 'tracker' do
    it 'should map everything to analytics' do
      get '/'
      last_response.should be_ok
      last_response.body.should include "Hello!"
    end

  end
end

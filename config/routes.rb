RedisAnalytics::Dashboard::Engine.routes.draw do
  root :to => 'visits#index'
  get '/visits', to: 'visits#index'
  get '/api/visits', to: 'api#visits'
  # get '/api/events', to: 'api#events'
end

RedisAnalytics::Dashboard::Engine.routes.draw do
  root :to => 'dashboards#index'
  get '/api/events/series', to: 'events#series'
  get '/api/events/aggregate', to: 'events#aggregate'
end

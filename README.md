## What is redis_analytics?

A gem that provides a Redis based web analytics solution for your rack compliant apps

## Why should I use it?

It gives you detailed analytics about visitors, unique visitors, browsers, OS, visitor recency, traffic sources and more

## OK, so how do I install it?

`gem install redis_analytics`

or in your `Gemfile`

```ruby
gem 'redis_analytics'
```

Make sure your redis server is running! Redis configuration is outside the scope of this README, but
check out the [Redis documentation](http://redis.io/documentation).

## How do I enable tracking in my rack-compliant app?

```ruby
# this is not required unless you use :require => false in your Gemfile
require 'redis_analytics'

# configure your redis connection (this is mandatory) and namespace (this is optional)
Rack::RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => '127.0.0.1')
  configuration.redis_namespace = 'mysite.org_analytics'
  
end
```

## Hey! Where do I view the dashboard?

### Option 1: If you are riding on rails, you can mount it

```ruby
# in your config/routes.rb
ExampleApp::Application.routes.draw do
  mount Rack::RedisAnalytics::Dashboard, :at => '/dashboard'
end
```

### Option 2: Simply run the binary executable file

`redis_analytics_dashboard --redis-host 127.0.0.1 --redis-port 6379 --redis-namespace mysite.org_analytics`

## Copyright

Copyright (c) 2012-2013 Schubert Cardozo. See LICENSE for further details.

## What is redis_analytics?

A gem that provides a Redis based web analytics solution for your rack compliant apps

## Why should I use it?

It gives you detailed analytics about visitors, unique visitors, browsers, OS, visitor recency, traffic sources and more

## Does it have a cool dashboard?

![Screenshot](https://github.com/saturnine/redis_analytics/raw/master/screenshot.png)

## OK, so how do I install it?

`gem install redis_analytics`

or in your `Gemfile`

```ruby
gem 'redis_analytics'
```

Make sure your redis server is running! Redis configuration is outside the scope of this README, but
check out the [Redis documentation](http://redis.io/documentation).

## How do I enable tracking in my rack-compliant app?

### Step 1: Load the redis_analytics library and configure it

```ruby
# this is not required unless you use :require => false in your Gemfile
require 'redis_analytics'

# configure your redis connection (this is mandatory) and namespace (this is optional)
Rack::RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
  configuration.redis_namespace = 'ra'
  
end
```
### Step 2: Use the Tracker rack middleware (NOT REQUIRED FOR RAILS)

```ruby
use Rack::RedisAnalytics::Tracker
```

## Where do I view the dashboard?

### Option 1: If you are riding on rails, you can mount it

```ruby
# in your config/routes.rb
ExampleApp::Application.routes.draw do
  mount Rack::RedisAnalytics::Dashboard, :at => '/dashboard'
end
```

and navigate to [http://localhost:3000/dashboard](http://localhost:3000/dashboard) assuming your rails app is hosted at [http://127.0.0.1:3000](http://localhost:3000)

### Option 2: Simply run the binary executable file

`redis_analytics_dashboard --redis-host 127.0.0.1 --redis-port 6379 --redis-namespace ra`

and navigate to [http://localhost:4567](http://localhost:4567)

## What if I have multiple rails apps that I want to track as one?

In the configuration, keep the value of redis_namespace the same across all your rails apps

```ruby
Rack::RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
  configuration.redis_namespace = 'mywebsite.org'

end
```
## Copyright

Copyright (c) 2012-2013 Schubert Cardozo. See LICENSE for further details.

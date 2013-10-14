## redis_analytics [![Build Status](https://travis-ci.org/saturnine/redis_analytics.png?branch=master)](https://travis-ci.org/saturnine/redis_analytics) [![Coverage Status](https://coveralls.io/repos/saturnine/redis_analytics/badge.png?branch=master)](https://coveralls.io/r/saturnine/redis_analytics)


### What is redis_analytics?

A gem that provides a Redis based web analytics solution for your rack-compliant apps

### Why should I use it?

It gives you detailed analytics about visitors, unique visitors, browsers, OS, visitor recency, traffic sources and more

### Does it have a cool dashboard?

Yes, It uses the excellent [Morris.js](http://www.oesmith.co.uk/morris.js/) for the main dashboard and [Highcharts](http://www.highcharts.com) for drawing the various detailed graphs

![Screenshot](https://github.com/saturnine/redis_analytics/raw/master/screenshot.png)

### OK, so how do I install it?

`gem install redis_analytics`

or in your `Gemfile`

```ruby
gem 'redis_analytics'
```

Make sure your redis server is running! Redis configuration is outside the scope of this README, but
check out the [Redis documentation](http://redis.io/documentation).

### How do I enable tracking in my rack-compliant app?

#### Step 1: Load the redis_analytics library and configure it

```ruby
# this is not required unless you use :require => false in your Gemfile
require 'redis_analytics'

# configure your redis connection (this is mandatory) and namespace (this is optional)
Rack::RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
  configuration.redis_namespace = 'ra'
end
```
#### Step 2: Use the Tracker rack middleware (NOT REQUIRED FOR RAILS)

```ruby
# in Sinatra you would do...
use Rack::RedisAnalytics::Tracker
```

For rails the middleware is added automatically, so you do not need to add it manually using `config.middleware.use`

### Where do I view the dashboard?

#### Option 1: Set a dashboard endpoint in your configuration

```ruby
Rack::RedisAnalytics.configure do |configuration|
  configuration.dashboard_endpoint = '/dashboard'
end
```

and navigate to [http://localhost:3000/dashboard](http://localhost:3000/dashboard) assuming your rack-compliant app is hosted at [http://localhost:3000](http://localhost:3000)

#### Option 2: Simply run the bundled Sinatra application binary

`redis_analytics_dashboard --redis-host 127.0.0.1 --redis-port 6379 --redis-namespace ra`

and navigate to [http://localhost:4567](http://localhost:4567)

### What if I have multiple rails apps that I want to track as one?

In the configuration, keep the value of redis_namespace the same across all your rails apps

```ruby
Rack::RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
  configuration.redis_namespace = 'mywebsite.org'
end
```

### Why is the Geolocation tracking giving me wrong results?

IP based Geolocation works using [MaxMind's](http://www.maxmind.com) GeoLite database. The free version is not as accurate as their commercial version. 
Also it is recommended to regularly get an updated binary of 'GeoLite Country' database from [here](http://dev.maxmind.com/geoip/geolite) and extract the GeoIP.dat file into a local directory.
You will then need to point to the GeoIP.dat file in your configuration.

```ruby
Rack::RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
  configuration.redis_namespace = 'mywebsite.org'
  configuration.geo_ip_data_path = '/path/to/GeoIP.dat'
end
```

## Customizing & Extending

### Tracking custom parameters (COMING SOON)

You can define and track your own parameters by defining an instance method inside the `Parameters` module

All you need to do, is make sure the method name conforms to the following format:

`[abc]_[x]_per_[y]`

where

`abc` is the parameter name and can be any alphanumeric (underscore allowed) characters  
`x` can be any one of `datum` or `count` and defines how this parameter will be tracked  
`y` can be any one of `hit` or `visit` and defines when this parameter will be tracked  

You can access the `Rack::Request` object via `@request` and the `Rack::Response` object via `@response` in your method

The return value of the method should be `Fixnum` for `count` and `String` for `datum`

If the return value is an `error` or `nil` the parameter won't be tracked

```ruby
module Rack::RedisAnalytics::Parameters

  # whenever a product is sold, i want to track it per product_id
  def product_sales_datum_per_hit
    if @request.path == '/product/sale'
      return @request.params['product_id']
    end
  end

  # whenever a product is viewed by a user, i want to track it per product & user
  def user_product_views_datum_per_hit
    if @request.path == '/product/info'
      return "#{@request.params['product_id']}_#{@request.params['user_id']}"
    end
  end

  # track the first page the user hit to enter the site
  def entry_page_datum_per_visit
    return @request.path
  end
  
  # how many times did a visitor reach the payment step
  def payment_step_count_per_hit
    return 1 if @request.path == '/payment'
  end

end
```

### Using filters

```ruby
Rack::RedisAnalytics.configure do |configuration|

  # simple string path filter
  configuration.add_path_filter('/robots.txt')

  # regexp path filter
  configuration.add_path_filter(/^\/favicon.ico$/)

  # generic filters
  configuration.add_filter do |request, response|
    request.params['layout'] == 'print'
  end

  # generic filters
  configuration.add_filter do |request, response|
    request.ip =~ /^172.16/ or request.ip =~ /^192.168/
  end

end
```

## How does it work?

![Screenshot](https://github.com/saturnine/redis_analytics/raw/master/wsd.png)

## Copyright

Copyright (c) 2012-2013 Schubert Cardozo. See LICENSE for further details.

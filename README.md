# redis_analytics [![Build Status](https://travis-ci.org/saturnine/redis_analytics.png?branch=master)](https://travis-ci.org/saturnine/redis_analytics) [![Coverage Status](https://coveralls.io/repos/saturnine/redis_analytics/badge.png?branch=master)](https://coveralls.io/r/saturnine/redis_analytics)


## What is redis_analytics?

A gem that provides a Redis based web analytics solution for your rack-compliant apps

## Why should I use it?

It gives you detailed analytics about visitors, unique visitors, browsers, OS, visitor recency, traffic sources and more

## Does it have a cool dashboard?

Yes, It uses the excellent [Morris.js](http://www.oesmith.co.uk/morris.js/) for the main dashboard and [Highcharts](http://www.highcharts.com) for drawing the various detailed graphs

![Screenshot](https://github.com/saturnine/redis_analytics/raw/master/screenshot.png)

## OK, so how do I install it?

```
gem install redis_analytics
```

or in your `Gemfile`

```ruby
# Gemfile
gem 'redis_analytics'
```

Make sure your redis server is running! Redis configuration is outside the scope of this README, but
check out the [Redis documentation](http://redis.io/documentation).

## How do I enable tracking in my rack-compliant app?

### Step 1: Load the redis_analytics library and configure it

```ruby
# config/initializers/redis_analytics.rb
# this is not required unless you use :require => false in your Gemfile
require 'redis_analytics'

Rack::RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
  configuration.redis_namespace = 'ra'
end
```
### Step 2: Use the Tracker rack middleware (NOT REQUIRED FOR RAILS)

```ruby
# in Sinatra you would do...
use Rack::RedisAnalytics::Tracker
```

For rails the middleware is added automatically, so you do not need to add it manually using `config.middleware.use`

## Where do I view the dashboard?

### Option 1: Set a dashboard endpoint in your configuration

```ruby
# config/initializers/redis_analytics.rb
Rack::RedisAnalytics.configure do |configuration|
  configuration.dashboard_endpoint = '/dashboard'
end
```

and navigate to [http://localhost:3000/dashboard](http://localhost:3000/dashboard) assuming your rack-compliant app is hosted at [http://localhost:3000](http://localhost:3000)

### Option 2: Simply run the bundled Sinatra application binary

`redis_analytics_dashboard --redis-host 127.0.0.1 --redis-port 6379 --redis-namespace ra`

and navigate to [http://localhost:4567](http://localhost:4567)

## What if I have multiple rails apps that I want to track as one?

In the configuration, keep the value of redis_namespace the same across all your rails apps

```ruby
# config/initializers/redis_analytics.rb
Rack::RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
  configuration.redis_namespace = 'mywebsite.org'
end
```

## How do I use filters?

```ruby
# config/initializers/redis_analytics.rb
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


## Why is the Geolocation tracking giving me wrong results?
By default geolocation is disabled.
You can use the GeoCoder or GeoIP.

### Geocoder

add in your `Gemfile`

```ruby
# Gemfile
gem 'geocoder'
```

```ruby
# config/initializers/redis_analytics.rb
require 'geocoder' # this is not required for Rails
Rack::RedisAnalytics.configure do |configuration|
  configuration.geo_engine = :geocoder
end
```


### GeoIP
IP based Geolocation works using [MaxMind's](http://www.maxmind.com) GeoLite database. The free version is not as accurate as their commercial version.
Also it is recommended to regularly get an updated binary of 'GeoLite Country' database from [here](http://dev.maxmind.com/geoip/geolite) and extract the GeoIP.dat file into a local directory.
You will then need to point to the GeoIP.dat file in your configuration.

```ruby
# Gemfile
gem 'geoip'
```

```ruby
# config/initializers/redis_analytics.rb
require 'geoip' # this is not required for Rails
Rack::RedisAnalytics.configure do |configuration|
  configuration.geo_engine = :geoip
  configuration.geo_ip_data_path = '/path/to/GeoIP.dat' # optional, default: "bin/GeoIP.dat"
end
```

## How does it work?

![Screenshot](https://github.com/saturnine/redis_analytics/raw/master/wsd.png)

## Copyright

Copyright (c) 2012-2013 Schubert Cardozo. See LICENSE for further details.

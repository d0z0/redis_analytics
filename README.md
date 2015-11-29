## redis_analytics [![Build Status](https://travis-ci.org/saturnine/redis_analytics.png?branch=master)](https://travis-ci.org/saturnine/redis_analytics) [![Coverage Status](https://coveralls.io/repos/saturnine/redis_analytics/badge.png?branch=master)](https://coveralls.io/r/saturnine/redis_analytics) [![Gem Version](https://badge.fury.io/rb/redis_analytics.png)](http://badge.fury.io/rb/redis_analytics)

A ruby gem that uses redis to track web analytics for your rails apps

### Why should I use it?

It gives you detailed analytics about visitors, unique visitors, browsers, OS, visitor recency, traffic sources, etc

### Does it have a cool dashboard?

Yes, It uses the excellent [Morris.js](http://morrisjs.github.io/morris.js/) for graphs/charts

![Screenshot](https://github.com/saturnine/redis_analytics/raw/master/screenshot.png)

### Cool! So how do I install it?

In your `Gemfile`

```ruby
gem 'redis_analytics'
```

Make sure your redis server is running! Redis configuration is outside the scope of this README, but
check out the [Redis documentation](http://redis.io/documentation).

### How do I enable tracking in my rails apps?

```ruby
require 'redis_analytics'

# configure your redis_connection (mandatory)
RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
end
```

### Where can I see the dashboard?

The Dashboard is a `Rails::Engine`. Just mount it into your `routes.rb` file at your favorite endpoint

```ruby
Rails.application.routes.draw do
  mount RedisAnalytics::Dashboard::Engine => "/dashboard"
end
```

and navigate to `/dashboard` in your app

### What if I have multiple rails apps that I want to track as one single website?

Just make sure you use the same `redis_connection` in the configuration for all your rails apps

```ruby
RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
end
```

### Why is the Geolocation tracking giving me wrong results?

IP based Geolocation works using [MaxMind's](http://www.maxmind.com) GeoLite database. The free version is not as accurate as their commercial version.
Also it is recommended to regularly get an updated binary of 'GeoLite Country' database from [here](http://dev.maxmind.com/geoip/geolite) and extract the GeoIP.dat file into a local directory.
You will then need to point to the GeoIP.dat file in your configuration.

```ruby
RedisAnalytics.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => 'localhost', :port => '6379')
  configuration.geo_ip_data_path = '/path/to/GeoIP.dat'
end
```

## Customizing & Extending

### Tracking custom metrics

You can define how to track custom metrics by creating an instance method inside the `RedisAnalytics::Metrics` module

```ruby
module RedisAnalytics::Metrics

  # methods to track custom metrics

end
```

RedisAnalytics only looks for method names which conform to the following format:

`[abc]_[x]_per_[y]`

where

* `abc` is a metric name
* `x` can be any one of `ratio` or `count` and defines the type of the metric
* `y` can be any one of `hit` or `visit` and defines how the metric will be tracked (once per hit or once per visit)

The return value of the method is important and should be `Fixnum` for `count` and `String` for `ratio` failing which, your metric might not work!

If the return value is an `error` or `nil` the metric won't be tracked at all

You can access the `Rack::Request` object via `@rack_request` and the `Rack::Response` object via `@rack_response` in your methods

You are free to define other methods that do not have the above format in the `Metrics` module as helper methods

```ruby
module RedisAnalytics::Metrics

  # TRACKING RATIOS

  # i want to track ratio of product views per product_id & user_id using query params
  def user_product_views_ratio_per_hit
    if @rack_request.path == '/product/info'
      return "#{@rack_request.params['product_id']}_#{@rack_request.params['user_id']}"
    end
  end

  # i want to track ratio of sold products by product_id using the URL `/products/:id/sale`
  def product_sales_ratio_per_hit
    if @rack_request.path =~ Regexp.new("\/product\/([0-9]+)\/sale")
      return $1
    end
  end

  # TRACKING COUNTS

  # i want to track how many times a visitor reached the payment step
  def payment_step_count_per_hit
    return 1 if @rack_request.path == '/payment'
  end

end
```

### Customizing the dashboard

Coming soon

### Using filters

```ruby
RedisAnalytics.configure do |configuration|

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

## Contributors Wanted

I may not be able to devote much time to this gem, but you are welcome to send me pull requests. See [CONTRIBUTING.md](CONTRIBUTING.md) to get started

## License

Since redis_analytics is licensed under MIT, you can use redis_analytics for free, provided you leave the attribution as is, in code as well as on the dashboard pages

Copyright (c) 2012-2014 Schubert Cardozo. See [MIT-LICENSE!](MIT-LICENSE) for further details.

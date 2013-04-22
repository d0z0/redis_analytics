# redis_analytics

A Redis based web analytics solution for your rack compliant apps

## Installation

`gem install redis_analytics`

or in your `Gemfile`

```ruby
gem 'redis_analytics'
```

Make sure your redis server is running! Redis configuration is outside the scope of this README, but
check out the [Redis documentation](http://redis.io/documentation).

## Configure

```ruby
Hashish.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => '127.0.0.1')
  configuration.redis_namespace = 'redis_analytics'
end
```

## Usage

Use redis_analytics:

```ruby
require 'redis_analytics'

# configure hashish first
Hashish.configure do |configuration|
  configuration.redis_connection = Redis.new(:host => '127.0.0.1')
  configuration.redis_namespace = 'redis_analytics'
  
end
```

## Copyright

Copyright (c) 2012-2013 Schubert Cardozo. See LICENSE for further details.

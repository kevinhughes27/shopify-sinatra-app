source 'https://rubygems.org'
ruby "2.0.0"

gem 'sinatra'
gem 'sinatra-redis'
gem 'sinatra-activerecord'
gem 'sinatra-twitter-bootstrap', require: 'sinatra/twitter-bootstrap'
gem 'rack-flash3', require: 'rack-flash'
gem 'activesupport'
gem 'attr_encrypted'
gem 'foreman'
gem 'rake'

gem 'resque', '~> 1.22.0'

gem 'omniauth-shopify-oauth2'
gem 'shopify_api'

group :production do
  gem 'pg'
end

group :development do
  gem 'sqlite3'
  gem 'rack-test'
  gem 'minitest'
  gem 'fakeweb'
  gem 'mocha', require: false
  gem 'byebug'
end

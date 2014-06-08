Gem::Specification.new do |s|
  s.name = 'shopify-sinatra-app'
  s.version = '0.0.1'

  s.summary     = "A classy shopify app"
  s.description = "A Sinatra extension for building Shopify Apps. Akin to the shopify_app gem but for Sinatra"

  s.authors = ["Kevin Hughes"]
  s.email = "kevin.hughes@shopify.com"
  s.homepage = "https://github.com/pickle27/shopify-sinatra-app/"

  s.files = `git ls-files`.split("\n")

  s.add_dependency 'sinatra'
  s.add_dependency 'activesupport'
  s.add_dependency 'attr_encrypted'
  s.add_dependency 'rack-flash3'
  s.add_dependency 'sinatra-twitter-bootstrap'
  s.add_dependency 'sinatra-redis'
  s.add_dependency 'resque', '~> 1.22.0'
  s.add_dependency 'rake'
  s.add_dependency 'foreman'

  s.add_dependency 'shopify_api'
  s.add_dependency 'omniauth-shopify-oauth2'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'fakeweb'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'byebug'
end

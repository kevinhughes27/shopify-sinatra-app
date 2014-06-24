Gem::Specification.new do |s|
  s.name = 'shopify-sinatra-app'
  s.version = '0.0.4'

  s.summary     = "A classy shopify app"
  s.description = "A Sinatra extension for building Shopify Apps. Akin to the shopify_app gem but for Sinatra"

  s.authors = ["Kevin Hughes"]
  s.email = "kevin.hughes@shopify.com"
  s.homepage = "https://github.com/pickle27/shopify-sinatra-app/"
  s.license = 'MIT'

  s.files = `git ls-files`.split("\n")
  s.executables << 'shopify-sinatra-app-generator'

  s.add_runtime_dependency 'sinatra'
  s.add_runtime_dependency 'sinatra-redis'
  s.add_runtime_dependency 'sinatra-activerecord'
  s.add_runtime_dependency 'sinatra-twitter-bootstrap'
  s.add_runtime_dependency 'rack-flash3'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'attr_encrypted'

  s.add_runtime_dependency 'resque', '~> 1.22.0'

  s.add_runtime_dependency 'shopify_api'
  s.add_runtime_dependency 'omniauth-shopify-oauth2'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'fakeweb'
  s.add_development_dependency 'mocha'
end

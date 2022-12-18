$VERBOSE = nil

ENV['RACK_ENV'] = 'test'
ENV['SECRET'] = 'secret'

require 'minitest/autorun'
require 'rack/test'
require 'mocha/minitest'
require 'fakeweb'

FakeWeb.allow_net_connect = false

module Helpers
  include Rack::Test::Methods

  def load_fixture(name)
    File.read("./test/fixtures/#{name}")
  end

  def fake(url, options = {})
    method = options.delete(:method) || :get
    body = options.delete(:body) || '{}'
    format = options.delete(:format) || :json

    FakeWeb.register_uri(method, url, { body: body, status: 200, content_type: "application/#{format}" }.merge(options))
  end
end

class Minitest::Test
  include Helpers
end

require 'sinatra/base'
require 'sinatra/activerecord'

require 'rack-flash'
require 'attr_encrypted'
require 'active_support/all'

require 'shopify_api'
require 'omniauth-shopify-oauth2'

module Sinatra
  module Shopify
    module Methods

      # designed to be overriden
      def after_shopify_auth
      end

      def logout
        session.delete(:shopify)
      end

      def base_url
        @base_url ||= "#{request_protocol}://#{request.env['HTTP_HOST']}"
      end

      def current_shop
        Shop.find_by(name: current_shop_name)
      end

      def current_shop_name
        return session[:shopify][:shop] if session.key?(:shopify)
        return @shop_name if @shop_name
      end

      def current_shop_url
        "https://#{current_shop_name}" if current_shop_name
      end

      def shopify_session(&blk)
        return_to = request.env['sinatra.route'].split(' ').last

        if !session.key?(:shopify)
          authenticate(return_to)
        elsif params[:shop].present? && session[:shopify][:shop] != sanitize_shop_param(params)
          logout
          authenticate(return_to)
        else
          shop_name = session[:shopify][:shop]
          token = session[:shopify][:token]
          activate_shopify_api(shop_name, token)
          yield
        end
      rescue ActiveResource::UnauthorizedAccess
        clear_session current_shop
        redirect request.env['sinatra.route'].split(' ').last
      end

      def shopify_webhook(&blk)
        return unless verify_shopify_webhook
        @shop_name = request.env['HTTP_X_SHOPIFY_SHOP_DOMAIN']
        webhook_body = ActiveSupport::JSON.decode(request.body.read.to_s)
        yield webhook_body
        status 200
      end

      private

      def request_protocol
        request.secure? ? 'https' : 'http'
      end

      def authenticate(return_to = '/')
        if shop_name = sanitized_shop_name
          redirect_url = "/auth/shopify?shop=#{shop_name}&return_to=#{base_url}#{return_to}"
          redirect_javascript redirect_url
        else
          redirect '/install'
        end
      end

      def activate_shopify_api(shop_name, token)
        api_session = ShopifyAPI::Session.new(shop_name, token)
        ShopifyAPI::Base.activate_session(api_session)
      end

      def clear_session(shop)
        logout
        shop.token = nil
        shop.save
      end

      def redirect_javascript(url)
        erb %(
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8" />
            <base target="_top">
            <title>Redirecting…</title>

            <script type='text/javascript'>
              // If the current window is the 'parent', change the URL by setting location.href
              if (window.top == window.self) {
                window.top.location.href = #{url.to_json};

              // If the current window is the 'child', change the parent's URL with postMessage
              } else {
                message = JSON.stringify({
                  message: 'Shopify.API.remoteRedirect',
                  data: { location: window.location.origin + #{url.to_json} }
                });
                window.parent.postMessage(message, 'https://#{sanitized_shop_name}');
              }
            </script>
          </head>
          <body>
          </body>
        </html>
        ), layout: false
      end

      def sanitized_shop_name
        @sanitized_shop_name ||= sanitize_shop_param(params)
      end

      def sanitize_shop_param(params)
        return unless params[:shop].present?
        name = params[:shop].to_s.strip
        name += '.myshopify.com' if !name.include?('myshopify.com') && !name.include?('.')
        name.gsub!('https://', '')
        name.gsub!('http://', '')

        u = URI("http://#{name}")
        u.host.ends_with?('.myshopify.com') ? u.host : nil
      end

      def verify_shopify_webhook
        data = request.body.read.to_s
        digest = OpenSSL::Digest.new('sha256')
        calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, settings.shared_secret, data)).strip
        request.body.rewind

        if calculated_hmac == request.env['HTTP_X_SHOPIFY_HMAC_SHA256']
          true
        else
          puts 'Shopify Webhook verifictation failed!'
          false
        end
      end
    end

    def self.registered(app)
      app.helpers Shopify::Methods
      app.register Sinatra::ActiveRecordExtension

      app.set :database_file, File.expand_path('config/database.yml')
      app.set :views, File.expand_path('views')
      app.set :public_folder, File.expand_path('public')
      app.set :erb, layout: :'layouts/application'
      app.set :protection, except: :frame_options

      app.enable :sessions
      app.enable :inline_templates

      app.set :scope, 'read_products, read_orders'

      app.set :api_key, ENV['SHOPIFY_API_KEY']
      app.set :shared_secret, ENV['SHOPIFY_SHARED_SECRET']
      app.set :secret, ENV['SECRET']

      app.use Rack::Flash, sweep: true
      app.use Rack::MethodOverride
      app.use Rack::Session::Cookie, key: 'rack.session',
                                     path: '/',
                                     secret: app.settings.secret,
                                     expire_after: 60 * 30 # half an hour in seconds

      app.use OmniAuth::Builder do
        provider :shopify,
                 app.settings.api_key,
                 app.settings.shared_secret,

                 scope: app.settings.scope,

                 setup: lambda { |env|
                   params = Rack::Utils.parse_query(env['QUERY_STRING'])
                   site_url = "https://#{params['shop']}"
                   env['omniauth.strategy'].options[:client_options][:site] = site_url
                 }
      end

      ShopifyAPI::Session.setup(
        api_key: app.settings.api_key,
        secret: app.settings.shared_secret
      )

      app.get '/install' do
        if params[:shop].present?
          authenticate
        else
          erb :install, layout: false
        end
      end

      app.post '/login' do
        authenticate
      end

      app.get '/logout' do
        logout
        redirect '/install'
      end

      app.get '/auth/shopify/callback' do
        shop_name = params['shop']
        token = request.env['omniauth.auth']['credentials']['token']

        shop = Shop.find_or_initialize_by(name: shop_name)
        shop.token = token
        shop.save!

        session[:shopify] = {
          shop: shop_name,
          token: token
        }

        after_shopify_auth()

        return_to = env['omniauth.params']['return_to']
        redirect return_to
      end

      app.get '/auth/failure' do
        erb "<h1>Authentication Failed:</h1>
             <h3>message:<h3> <pre>#{params}</pre>", layout: false
      end
    end
  end

  register Shopify
end

class Shop < ActiveRecord::Base
  def self.secret
    @secret ||= ENV['SECRET']
  end

  attr_encrypted :token,
    key: secret,
    attribute: 'token_encrypted',
    mode: :single_iv_and_salt,
    algorithm: 'aes-256-cbc',
    insecure_mode: true

  validates_presence_of :name
  validates_presence_of :token, on: :create
end

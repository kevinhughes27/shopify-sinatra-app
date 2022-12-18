require 'sinatra/base'
require 'sinatra/activerecord'

require 'attr_encrypted'
require 'active_support/all'

require 'shopify_api'
require 'omniauth-shopify-oauth2'

module Sinatra
  module Shopify
    module Methods

      # designed to be overridden
      def after_shopify_auth
      end

      # for the app bridge initializer
      def shop_host
        "#{session[:shopify][:host]}"
      end

      def shopify_session(&blk)
        return_to = request.path
        return_params = request.params

        if no_session?
          authenticate(return_to, return_params)

        elsif different_shop?
          clear_session
          authenticate(return_to, return_params)

        else
          shop_name = session[:shopify][:shop]
          token = session[:shopify][:token]
          activate_shopify_api(shop_name, token)
          yield shop_name
        end

      rescue ActiveResource::UnauthorizedAccess
        clear_session

        shop = Shop.find_by(name: shop_name)
        shop.token = nil
        shop.save

        redirect request.path
      end

      private

      def authenticate(return_to = '/', return_params = nil)
        session[:return_params] = return_params if return_params

        if shop_name = sanitized_shop_param(params)
          redirect "/login?shop=#{shop_name}"
        else
          redirect '/login'
        end
      end

      def base_url
        request_protocol = request.secure? ? 'https' : 'http'
        "#{request_protocol}://#{request.env['HTTP_HOST']}"
      end

      def no_session?
        !session.key?(:shopify)
      end

      def different_shop?
        params[:shop].present? && session[:shopify][:shop] != sanitized_shop_param(params)
      end

      def clear_session
        session.delete(:shopify)
        session.clear
      end

      def activate_shopify_api(shop_name, token)
        api_session = ShopifyAPI::Session.new(domain: shop_name, token: token, api_version: settings.api_version)
        ShopifyAPI::Base.activate_session(api_session)
      end

      def receive_webhook(&blk)
        return unless verify_shopify_webhook
        shop_name = request.env['HTTP_X_SHOPIFY_SHOP_DOMAIN']
        webhook_body = ActiveSupport::JSON.decode(request.body.read.to_s)
        yield shop_name, webhook_body
        status 200
      end

      def sanitized_shop_param(params)
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
          puts 'Shopify Webhook verification failed!'
          false
        end
      end
    end

    # needs to be dynamic to incude the current shop
    class ContentSecurityPolicy < Rack::Protection::Base
      def csp_policy(env)
        "frame-ancestors: #{current_shop(env)} https://admin.shopify.com;"
      end

      def call(env)
        status, headers, body = @app.call(env)
        header = 'Content-Security-Policy'
        headers[header] ||= csp_policy(env) if html? headers
        [status, headers, body]
      end

      private

      def current_shop(env)
        s = session(env)
        if s.has_key?("return_params")
          "https://#{s["return_params"]["shop"]}"
        elsif s.has_key?(:shopify)
          "https://#{s[:shopify][:shop]}"
        end
      end

      def html?(headers)
        return false unless (header = headers.detect { |k, _v| k.downcase == 'content-type' })

        options[:html_types].include? header.last[%r{^\w+/\w+}]
      end
    end

    def shopify_webhook(route, &blk)
      settings.webhook_routes << route
      post(route) do
        receive_webhook(&blk)
      end
    end

    def self.registered(app)
      app.helpers Shopify::Methods
      app.register Sinatra::ActiveRecordExtension

      app.set :database_file, File.expand_path('config/database.yml')

      app.set :erb, layout: :'layouts/application'
      app.set :views, File.expand_path('views')
      app.set :public_folder, File.expand_path('public')
      app.enable :inline_templates

      app.set :protection, except: :frame_options

      app.set :api_version, '2019-07'
      app.set :scope, 'read_products, read_orders'

      app.set :api_key, ENV['SHOPIFY_API_KEY']
      app.set :shared_secret, ENV['SHOPIFY_SHARED_SECRET']
      app.set :secret, ENV['SECRET']

      # csrf needs to be disabled for webhook routes
      app.set :webhook_routes, ['/uninstall']

      # add support for put/patch/delete
      app.use Rack::MethodOverride

      app.use Rack::Session::Cookie, key: 'rack.session',
                                     path: '/',
                                     secure: true,
                                     same_site: 'None',
                                     secret: app.settings.secret,
                                     expire_after: 60 * 30 # half an hour in seconds

      app.use Shopify::ContentSecurityPolicy

      app.use Rack::Protection::AuthenticityToken, allow_if: lambda { |env|
        app.settings.webhook_routes.include?(env["PATH_INFO"])
      }

      OmniAuth.config.allowed_request_methods = [:post]

      app.use OmniAuth::Builder do
        provider :shopify,
          app.settings.api_key,
          app.settings.shared_secret,
          scope: app.settings.scope,
          setup: lambda { |env|
            shop = if env['REQUEST_METHOD'] == 'POST'
              env['rack.request.form_hash']['shop']
            else
              Rack::Utils.parse_query(env['QUERY_STRING'])['shop']
            end

            site_url = "https://#{shop}"
            env['omniauth.strategy'].options[:client_options][:site] = site_url
          }
      end

      ShopifyAPI::Session.setup(
        api_key: app.settings.api_key,
        secret: app.settings.shared_secret
      )

      app.get '/login' do
        erb :login, layout: false
      end

      app.get '/logout' do
        clear_session
        redirect '/login'
      end

      app.get '/auth/shopify/callback' do
        shop_name = params['shop']
        token = request.env['omniauth.auth']['credentials']['token']
        host = params['host']

        shop = Shop.find_or_initialize_by(name: shop_name)
        shop.token = token
        shop.save!

        session[:shopify] = {
          shop: shop_name,
          host: host,
          token: token
        }

        after_shopify_auth()

        return_params = session[:return_params]
        session.delete(:return_params)

        return_to = '/'
        return_to += "?#{return_params.to_query}" if return_params.present?

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

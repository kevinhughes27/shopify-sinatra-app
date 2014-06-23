require 'sinatra/shopify-sinatra-app'

class SinatraApp < Sinatra::Base
  register Sinatra::Shopify

  get '/' do
    # your app's Home page
    shopify_session do |shop_name|
      @shop = Shop.find_by(:name => shop_name)
      @products = ShopifyAPI::Product.all(limit: 5)
      erb :home
    end
  end

  private

  def install
    # setup any webhooks or services you need when your app is installed
    shopify_session do |shop_name|
      params = YAML.load(File.read("config/app.yml"))

      # create the uninstall webhook
      uninstall_webhook = ShopifyAPI::Webhook.new(params["uninstall_webhook"])
      unless ShopifyAPI::Webhook.find(:all).include?(uninstall_webhook)
        uninstall_webhook.save
      end
    end
    redirect '/'
  end

  def uninstall
    # remove data for a shop when they uninstall your app
    webhook_session do |shop, params|
      shop.destroy
    end
  end

end

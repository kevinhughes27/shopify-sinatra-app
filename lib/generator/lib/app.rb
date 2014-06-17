require 'sinatra/shopify-sinatra-app'

class SinatraApp < Sinatra::Base
  register Sinatra::Shopify

  # Home page
  get '/' do
    shopify_session do |shop_name|
      erb :home
    end
  end

  private

  def install
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
    webhook_session do |shop, params|
      # delete all db entries for the shop on uninstall
      shop.destroy
    end
  end

end

require 'test_helper'
require './src/app'

class MockShop
  def initialize(shop_name)
    @shop_name = shop_name
  end

  def myshopify_domain
    @shop_name
  end
end

class AppTest < Minitest::Test
  def app
    SinatraApp
  end

  def setup
    @shop_name = 'testshop.myshopify.com'
    @shopify_shop = MockShop.new(@shop_name)
  end

  def test_root_with_session
    set_session
    fake 'https://testshop.myshopify.com/admin/shop.json', body: {myshopify_domain: @shop_name}.to_json
    fake 'https://testshop.myshopify.com/admin/products.json?limit=10', body: '{}'
    get '/'
    assert last_response.ok?
  end

  def test_root_with_session_activates_api
    set_session
    SinatraApp.any_instance.expects(:activate_shopify_api).with(@shop_name, 'token')
    ShopifyAPI::Shop.expects(:current).returns(@shopify_shop)
    ShopifyAPI::Product.expects(:find).returns([])
    get '/'
    assert last_response.ok?
  end

  def test_root_without_session_redirects_to_install
    get '/'
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/install', last_response.location
  end

  def test_root_with_shop_redirects_to_auth
    get '/?shop=othertestshop.myshopify.com'
    assert_match '/auth/shopify?shop=othertestshop.myshopify.com', last_response.body
  end

  def test_root_with_session_and_new_shop_redirects_to_auth
    set_session
    get '/?shop=othertestshop.myshopify.com'
    assert_match '/auth/shopify?shop=othertestshop.myshopify.com', last_response.body
  end

  def test_root_rescues_UnauthorizedAccess_clears_session_and_redirects
    set_session
    SinatraApp.any_instance.expects(:activate_shopify_api).with(@shop_name, 'token')
    SinatraApp.any_instance.expects(:clear_session)
    ShopifyAPI::Shop.expects(:current).raises(ActiveResource::UnauthorizedAccess.new('UnauthorizedAccess'))
    get '/'
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/', last_response.location
  end

  def test_uninstall_webhook_endpoint
    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    Shop.any_instance.expects(:destroy)
    post '/uninstall', '{}', 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop_name
    assert last_response.ok?
  end

  private

  def set_session(shop = 'testshop.myshopify.com', token = 'token')
    SinatraApp.any_instance.stubs(:session).returns(shopify: { shop: shop, token: token })
  end
end

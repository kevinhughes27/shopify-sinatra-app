shopify-sinatra-app
===================

"A classy shopify app"


Getting Started
---------------

Install the gem:

```
gem install shopify-sinatra-app
```

or build from source

```
gem build shopify-sinatra-app.gemspec
gem install shopify-sinatra-app-X.X.X.gem
```

To create a new app use the generator:

```
shopify-sinatra-app-generator new <your new app name>
```

This will create a new skeleton shopify-sinatra-app. The generator will create several default files for you rather than having them bundled in the sinatra extension - its worthwhile to read this section to understand what each of these files is for.

`config/app.yml` --> Some important config information is contained in this file.
  * scope: The scope of your app (what your app can access from the Shopify store once installed, e.g. read_products), this will be read by your app and used when your app is installed.

  * uninstall_webhook: Initially an uninstall webhook is also defined in this file, although without a proper url, this file is a good place to define objects that need to be created on Shopify when your app is installed like webhooks, fulfillment and carrier services.

`config/database.yml` --> The database config for active record. Initially this is setup to use sqlite3 for development and testing which you may want to change to mimic your production database.

`config.ru` --> Rackup file - describes how to run a rack based app

`Gemfile` --> manages the dependencies of the app

`lib/app.rb` --> This file is the skeleton app file. More details on how to use the methods provided by this extension are given in the following section.

`Procfile` --> Specific for deploying to Heroku, this file tells heroku how to run the app

`public/icon.png` --> This icon file is used by the Shopify Embedded App SKD and is shown in the menu bar of your embedded app

`Rakefile` --> includes some helper methods etc for running and managing the app. Standard for ruby based projects

`views/layouts/appliction.erb` --> This is the layout file that all templates will use unless otherwise specified. It sets up some defaults for using the Shopify Embedded App SDK and Twitter Bootstrap for styling

`views/_top_bar.erb` --> This is a partial view that describes the top bar inside a Shopify Embedded App. It also has some code to *forward* flash messages to the Embedded App SKD

`views/*` --> The other views used by the app. You'll probably make a lot of changes to home.erb and install.erb to customize the experience for your app


### Setting the app to use your Shopify API credentials

You'll need to create a Shopify Partner Account and a new application. You can make an account [here](http://www.shopify.ca/partners) and see this [tutorial](http://docs.shopify.com/api/the-basics/getting-started) for creating a new application.

Note - The shopify-sinatra-app creates an embedded app! You need change the embedded setting to enabled in the [Shopify Partner area](https://app.shopify.com/services/partners/api_clients) for your app. If you don't want your app to be embedded then remove the related code in `layout/application.erb` and delete the `layout/_top_bar.erb` file and the references to it in the other views.

Also note that when developing locally you'll need to enable unsafe javascripts in your browser for the embedded sdk to function. Read more [here](http://docs.shopify.com/embedded-app-sdk/getting-started)

After creating your new application you need to create a `.env` file and add the following lines:

```
SHOPIFY_API_KEY=<your api key>
SHOPIFY_SHARED_SECRET=<your shared secret>
SECRET=<generate a random string to encrypt credentials with>
```


Shopify::Methods
----------------

`shopify_session` - The main method of the framework, most of your routes will use this method to acquire a valid shopify session and then perform api calls to Shopfiy. The method simply takes a block of code and makes the shop_name available to you after activating an api session. Here is an example endpoint that displays products:

```ruby
get '/products.json' do
  shopify_session do |shop_name|
    products = ShopifyAPI::Product.all(limit: 5)
    products.to_json
  end
end
```

`webhook_session` - This method is for an endpoint that recieves a webhook from Shopify. Webhooks are a great way to keep your app in sync with a shop's data without polling. You can read more about webhooks [here](http://docs.shopify.com/api/tutorials/using-webhooks). This method also takes a block of code and makes the shop and webhook data as a hash available (note only works for json webhooks, don't use xml). Here is an example that listens to a order creation webhook:

```ruby
post '/order.json' do
  webhook_session do |shop, params|
    # do something with the data
  end
end
```

`webhook_job` - Its impossible to control the flow of webhooks to your app from Shopify especially if a larger store installs your app or if a shop has a flash sale. To prevent your app from getting overloaded with webhook requests it is usually a good idea to process webhooks in a background queue and return a 200 to Shopify immediately. This method provides this functionality using redis and resque. This method takes the name of a job class whose perform method expects a `shop_name` and the webhook data as a hash. The session method is useful for prototpying and experimenting but production apps should use `webhook_job`. Here is an example:

```ruby
post '/order.json' do
  webhook_job(OrderWebhookJob)
end

class OrderWebhookJob
  @queue = :default

  def self.perform(shop_name, params)
    # do something with the data
  end
end
```

`install` - This is a private method provided with the framework that gets called when the app is authorized for the first time. You should fill this method in with anything you need to initialize on install, for example webhooks and services on shopify or any other database models you have created specific to a shop.

`uninstall` - This method gets called when your app recieves an uninstall webhook from shopify. You should override this method in your class and do any appropriate clean up when the app is removed from a shop.

`logout` - This method clears the current session data in the app

`current_shop` - Returns the name of the current shop

`base_url` - This returns the url of the app


Deploying
---------

This template was created with deploying to Heroku in mind. Heroku is a great cloud based app hosting provider that makes it incredibly easy to get an application into a product environment.

Before you can get started with Heroku you need to create a git repo for you application:

```
git init
git add .
git commit -m "initial commit"
```

Now you can create a new heroku application. Download the [Heroku Toolbelt](https://devcenter.heroku.com/articles/quickstart) and run the following command to create a new application:

```
heroku apps:create <your new app name>
```

You will also need to add the following (free) add-ons to your new Heroku app:

```
heroku addons:add heroku-postgresql
heroku addons:add rediscloud
```

Now we can deploy the new application to Heroku. Deploying to Heroku is as simple as pushing the code using git:

```
git push heroku master
```

A `rake deploy2heroku` command is included in the generated Rakefile which does just this.

Now that our application is deployed we need to run `rake db:migrate` to initialize our database on Heroku. To do this run:

```
heroku run rake db:migrate
```

We also need to set our environment variables on Heroku. The environment variables are stored in `.env` and are not tracked by git. This is to protect your credentials in the case of a source control breach. Heroku provides a command to set environment variables: `heroku config:set VAR=foo`. In the generated Rakefile there is a helper method that will properly set all the variables in your `.env` file:

```
rake creds2heroku
```

and make sure you have at least 1 dyno for web and resque:

```
heroku scale web=1 resque=1
```

Note - if you are not using any background queue for processing webhooks then you do not need the redis add-on or the resque dyno so you can set it to 0.

Make sure you set your shopify apps url to your Heroku app url in the Shopify Partner area https://app.shopify.com/services/partners/api_clients.

Contributing
------------

PRs welcome!

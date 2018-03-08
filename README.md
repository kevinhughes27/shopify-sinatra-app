shopify-sinatra-app [![Build Status](https://travis-ci.org/kevinhughes27/shopify-tax-receipts.svg)](https://travis-ci.org/kevinhughes27/shopify-sinatra-app)
===================

"A classy shopify app"

shopify-sinatra-app is lightweight extension for building Shopify apps using Sinatra. It comes with the Shopify API gem for interacting with the Shopify API and uses the Shopify omniauth gem to handle authentication via Oauth (other auth methods are not supported). The framework itself provides a handful of helper methods to make creating your app as easy as possible. The framework was designed with deployment to Heroku in mind and following the instructions below I've been able to create a new application from scratch, deploy it to Heroku and install on my live test shop in less than 5 minutes.


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

`config/database.yml` --> The database config for active record. Initially this is setup to use sqlite3 for development and testing which you may want to change to mimic your production database.

`.gitignore` --> tells git which files to ignore, namely `.env` you may find more things you want to add to this file.

`.env` --> a hidden file not tracked by source control for storing credentials etc. to be set as environment variables

`config.ru` --> Rackup file - describes how to run a rack based app

`Gemfile` --> manages the dependencies of the app

`src/app.rb` --> This file is the skeleton app file. More details on how to use the methods provided by this extension are given in the following section. There are more comments inside this file explaining the skeleton app.

`Procfile` --> Specific for deploying to Heroku, this file tells heroku how to run the app

`public/icon.png` --> This icon file is used by the Shopify Embedded App SKD and is shown in the menu bar of your embedded app

`Rakefile` --> includes some helper methods etc for running and managing the app. Standard for ruby based projects

`views/layouts/appliction.erb` --> This is the layout file that all templates will use unless otherwise specified. It sets up some defaults for using the Shopify Embedded App SDK and Twitter Bootstrap for styling

`views/_top_bar.erb` --> This is a partial view that describes the top bar inside a Shopify Embedded App. It also has some code to *forward* flash messages to the Embedded App SKD

`views/*` --> The other views used by the app. You'll probably make a lot of changes to home.erb and install.erb to customize the experience for your app

`test/*` --> Test files, fixtures and helpers for testing your app.

### Setting the app to use your Shopify API credentials

You'll need to create a Shopify Partner Account and a new application. You can make an account [here](http://www.shopify.ca/partners) and see this [tutorial](http://docs.shopify.com/api/the-basics/getting-started) for creating a new application. This app uses the default redirect_uri from omniauth `<your domain>/auth/shopify/callback` so set it accordingly when creating your app.

Note - The shopify-sinatra-app creates an embedded app! You need change the embedded setting to `enabled` in the [Shopify Partner area](https://app.shopify.com/services/partners/api_clients) for your app. If you don't want your app to be embedded then remove the related code in `layout/application.erb` and delete the `layout/_top_bar.erb` file and the references to it in the other views.

After creating your new application you need to edit the `.env` file and add the following lines:

```
SHOPIFY_API_KEY=<your api key>
SHOPIFY_SHARED_SECRET=<your shared secret>
SECRET=<generate a random string to encrypt credentials with>
```

If your app has any other secret credentials you should add them to this file.


Shopify::Methods
----------------

**shopify_session** - The main method of the framework, most of your routes will use this method to acquire a valid shopify session and then perform api calls to Shopfiy. The method activates a Shopify API session for you and accepts a block inside of which you can use the ShopifyAPI. Here is an example endpoint that displays products:

```ruby
get '/products.json' do
  shopify_session do
    products = ShopifyAPI::Product.all(limit: 5)
    products.to_json
  end
end
```

**webhook_session** - This method is for an endpoint that recieves a webhook from Shopify. Webhooks are a great way to keep your app in sync with a shop's data without polling. You can read more about webhooks [here](http://docs.shopify.com/api/tutorials/using-webhooks). This method also takes a block of code and yields the `webhook_data` as a hash (note only works for json webhooks, don't use xml). Here is an example that listens to an order creation webhook:

```ruby
post '/order.json' do
  webhook_session do |webhook_data|
    # do something with the data
  end
end
```

**webhook_job** - Its impossible to control the flow of webhooks to your app from Shopify especially if a larger store installs your app or if a shop has a flash sale. To prevent your app from getting overloaded with webhook requests it is usually a good idea to process webhooks in a background queue and return a `200` to Shopify immediately. This method provides this functionality using redis and resque. This method takes the name of a job class whose perform method expects a `shop_name`, `shop_token` and the `webhook_data` as a hash. The session method is useful for prototpying and experimenting but production apps should use `webhook_job`. Here is an example:

```ruby
post '/order.json' do
  webhook_job(OrderWebhookJob)
end

class OrderWebhookJob
  @queue = :default

  def self.perform(shop_name, shop_token, webhook_data)
    # do something with the data
  end
end
```

**after_shopify_auth** - This is a private method provided with the framework that gets called whenever the app is authorized. You should fill this method in with anything you need to initialize, for example webhooks and services on Shopify or any other database models you have created specific to a shop. Note that this method will be called anytime the auth flow is completed so this method should be idempotent (running it twice has the same effect as running it once).

**logout** - This method clears the current session

**current_shop_name** - Returns the name of the current shop (format: example.myshopify.com)

**current_shop_url** - Returns the url of the current shop (format: https://example.myshopify.com)

**current_shop** - Returns the activerecord model of the current shop. Use carefully!

**base_url** - This returns the url of the app

shopify-sinatra-app includes sinatra/activerecord for creating models that can be persisted in the database. You might want to read more about sinatra/activerecord and the methods it makes available to you: [https://github.com/janko-m/sinatra-activerecord](https://github.com/janko-m/sinatra-activerecord)

shopify-sinatra-app also includes `rack-flash3` and the flash messages are forwarded to the Shopify Embedded App SDK (see the code in `views/layouts/application.erb`). Flash messages are useful for signaling to your users that a request was successful without changing the page. The following is an example of how to use a flash message in a route:

```
post '/flash_message' do
  flash[:notice] = "Flash Message!"
  redirect '/'
end
```

note - a flash must be followed by a redirect or it won't work!


Developing
----------
The embedded app sdk won't load non https content so you'll need to use a forwarding service like [ngrok](https://ngrok.com/) or [forwardhq](https://forwardhq.com/). Set your application url in the [Shopify Partner area](https://app.shopify.com/services/partners/api_clients) to your forwarded url. However The redirect_uri should still be `http://localhost:4567/auth/shopify/callback` which will allow you to install your app on a live shop while running it locally.

To run the app locally we use `foreman` which comes with the [Heroku Toolbelt](https://devcenter.heroku.com/articles/quickstart). Foreman handles running our application and setting our credentials as environment variables. To run the application type:

```
foreman run bundle exec rackup config.ru
```

Note - we use `foreman run ...` not `foreman start ...` because we only want to start the single process that is our app. This means if you add a debugger in your app it will trigger properly in the command line when the debugger is hit. If you don't have any debuggers feel free to use `foreman start -p 4567`.

To debug your app simply add `require 'byebug'` at the top and then type `byebug` where you would like to drop into an interactive session. You may also want to try out [Pry](http://pryrepl.org/).

If you are testing webhooks locally make sure they also go through the forwarded url and not `localhost`.


Testing
-------

Some basic tests are included in the generated app. To run them simply run:

```
bundle exec rake test:prepare
bundle exec rake test
```

`test:prepare` will initialize your testing database using the `seeds.rb` file. If you have added additional models you can add them here.

Checkout the contents of the `app_test.rb` file and the `test_helper.rb` and modify them as you add functionality to your app. You can also check the tests of other apps using this framework to see more about how to write tests for your own app.


Deploying
---------

This template was created with deploying to Heroku in mind. Heroku is a cloud based app hosting provider that makes it easy to get an application into a product environment.

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

Make sure you set your shopify apps url to your Heroku app url (and make sure to use the `https` version or else the Embedded App SDK won't work) in the Shopify Partner area https://app.shopify.com/services/partners/api_clients.


Apps using this framework
-------------------------

* [shopify-fulfillment-integration](https://github.com/Shopify/shopify-fulfillment-integration)
* [shopify-tax-receipts](https://github.com/pickle27/shopify-tax-receipts)
* Add yours!


Contributing
------------

PRs welcome!

Note - this framework does have tests! They are the same tests that get generated for new apps by the generator. You can run them with `./test.sh`

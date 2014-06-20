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

After creating your new application you need to create a `.env` file and add the following lines:

```
SHOPIFY_API_KEY=<your api key>
SHOPIFY_SHARED_SECRET=<your shared secret>
SECRET=<generate a random string to encrypt credentials with>
```


Shopify::Methods
----------------

install

uninstall

logout

shopify_session

webhook_session

webhook_job

current_shop

base_url


Deploying
---------

This template was created with deploying to Heroku in mind. Heroku is a great cloud based app hosting provider that makes it incredibly easy to get an application into a product environment. To create a new heroku application download the [Heroku Toolbelt](https://devcenter.heroku.com/articles/quickstart) and create a new application:

```
heroku apps:create <my_fulfillment_app>
```

You will also need to add the following (free) add-ons to your new Heroku app:

```
heroku addons:add heroku-postgresql
heroku addons:add rediscloud
```

and make sure you have at least 1 dyno for web and resque:

```
heroku scale web=1 resque=1
```

Note - if you are not using any background queue for processing webhooks then you do not need the redis add-on or the resque dyno so you can set it to 0.

Contributing
------------

PRs welcome!

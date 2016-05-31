Twitter API Usage Sample
========================
This is a Ruby on Rails app which provides a chart that rounds up the tweets of 2016 of a tweet handle broke down to a time series of the last 6 months.

Insert an username and get the amount of tweets in the last 6 months of that user.

Two approach are provided in different branches:
* master: A solution using the [twitter gem](https://github.com/sferik/twitter)
* custom_api: A solution using a custom lib that provides an abstraction to the Twitter API

Install
=======
Checkout the source, go into the folder and run `bundle install` (You ned the [bundler gem](http://bundler.io/)).

After install the necessary gems configure the Twitter API keys in the file `config/app_environment_variables.rb`

    ENV['API_KEY'] = 'YOUR_API_KEY'
    ENV['API_SECRET'] = 'YOUR_API_SECRET'
    ENV['ACCESS_TOKEN'] = 'YOUR_ACCESS_TOKEN'
    ENV['ACCESS_TOKEN_SECRET'] = 'YOUR_ACCESS_TOKEN_SECRET'

Usage
=====
Run `rails server` and go to http://localhost:3000/ in the browser

Ruby version
============
ruby-2.3.1
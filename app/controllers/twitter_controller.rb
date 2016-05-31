class TwitterController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Homepage controller
  def view_chart
  end

  # This function provides a json with the number of tweets in every month in the lasts six months
  def get_tweets_last_six_months
    # screen_name is needed to make the calculations
    params.require(:screen_name)
    screen_name = params[:screen_name].strip

    # Get the API keys from the environment variables
    api_key = ENV['API_KEY']
    api_secret = ENV['API_SECRET']
    access_token = ENV['ACCESS_TOKEN']
    access_token_secret = ENV['ACCESS_TOKEN_SECRET']

    # Create the Twitter::REST::Client instance
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = api_key
      config.consumer_secret     = api_secret
      config.access_token        = access_token
      config.access_token_secret = access_token_secret
    end

    # Check if the user exists
    exists = true
    begin
      user = client.user(screen_name)
    rescue Twitter::Error::NotFound => detail
      exists = false
    end

    if exists
      # Get the tweets in the last 6 months
      result = get_6_months_tweets(client, screen_name)
    else
      result = { "error": "User does not exists" }
    end

    render json: result
  end

  private


  # Get tweets in the last 6 months from the user.
  # The screen_name has to be a user name of an existing user.
  def get_6_months_tweets(client, screen_name)
    # To not reach the rate limit of the Twitter API, we get 200 (the maximum) tweets in each request
    # until we have the tweets in the last 6 months or older.
    # As we can get older tweets, after the necessary request, we will get rid of that older tweets

    # Get the oldest date
    today = DateTime.now.to_date
    six_month_ago = today.beginning_of_month - 5.month

    begin
      # Make the API call to the 200 newest tweets
      tweets = client.user_timeline(screen_name, :count => 200)

      # If we have any results, check:
      #   - if the last tweet is older than 6 month from now --> We do not need more tweets
      #   - if the last tweet is not older than 6 month from now --> get another 200 tweets and append to the tweet we already have
      # Repeat this proccess until the lasr tweet is older than 6 month from now
      while tweets.any? && tweets.last.created_at >= six_month_ago do
        more_tweets = client.user_timeline(screen_name, :count => 200, :max_id => tweets.last.id - 1)
        tweets += more_tweets
      end

      # Get rid of the tweets older than 6 month from now
      tweets_in_months = [];
      tweets.each do |tweet|
        if tweet.created_at >=six_month_ago
          tweets_in_months << tweet
        else
          break
        end
      end

      # Divide the tweets per months
      result = divide_tweets_per_month(tweets_in_months)
    rescue Exception => e
      result = e
    end

    return result
  end

  # this function divide the tweets per month.
  # The result is an hash with the first day of the every month as keys and the number of tweets in that month in the value
  def divide_tweets_per_month(tweets)
    result = {};

    # Initialize the hash to 0
    today = DateTime.now.to_date
    (0..5).to_a.reverse.each do |i|
      date = today.beginning_of_month - i.month

      result[date.beginning_of_month] = 0
    end

    # For each tweet add 1 to the number of tweets in the correct month
    tweets.each do |tweet|
      tweet_date = tweet.created_at.to_date

      result[tweet_date.beginning_of_month] += 1
    end

    return result
  end
end

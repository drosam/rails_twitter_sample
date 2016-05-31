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

    require "custom_twitter_api"

    # Get the API keys from the environment variables
    api_key = ENV['API_KEY']
    api_secret = ENV['API_SECRET']

    # Create the CustomTwitterAPI instance
    twitter_api = CustomTwitterAPI.new(api_key, api_secret)

    # Check if the user exists
    if twitter_api.check_user_exists?(screen_name)
      # Get the tweets in the last 6 months
      tweets = twitter_api.get_tweets_last_6_months(screen_name)

      # If get any error return it
      if tweets.include?("errors")
        result = tweets
      else
        # Divide the tweets per months
        result = divide_tweets_per_month(tweets)
      end
    else
      result = { "error": "User does not exists" }
    end

    # Return the result
    render json: result
  end

  private

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
      tweet_date =  Date.parse(tweet["created_at"])

      result[tweet_date.beginning_of_month] += 1
    end

    return result
  end
end

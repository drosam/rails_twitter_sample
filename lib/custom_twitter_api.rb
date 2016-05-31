# This class provides acces to the Twitter API.
# Any kind of request can be added to this class in order to abstract the user about the Twitter API details
class CustomTwitterAPI
  require 'uri'
  require "net/http"
  require "base64"

  public

  # Constructor
  def initialize(api_key = '', api_secret = '')
    # Prepare the api key to make the requests
    @api_key = URI::encode(api_key)
    @api_secret = URI::encode(api_secret)
    @api_key_secret_base_64 = Base64.strict_encode64("#{@api_key}:#{@api_secret}")
  end

  # This function check if an user exists
  def check_user_exists?(screen_name)
    params = { :screen_name => screen_name }

    # API URL
    access_token = get_access_token
    url = URI.parse("https://api.twitter.com/1.1/users/lookup.json")
    url.query = URI.encode_www_form( params )

    # Pepare the request
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(url.request_uri)
    req["Authorization"] = "Bearer #{access_token}"

    # Make the request
    request_result = http.request(req)

    # Get the response and parse it
    request_body = JSON.parse(request_result.body)

    result = true
    # If the response has an error, then the user does not exists
    if request_body.include?("errors")
      result = false
    end

    return result
  end

  # Get tweets from the user. filters is a hash with at least a key named screen_name, that contains the user name.
  # The screen_name has to be a user name of an existing user.
  # filster can have any other keys accepted by the user_timeline API function from the Twitter API
  def get_user_timeline(filters)
    # Get the acces token
    access_token = get_access_token

    # API URL
    url = URI.parse("https://api.twitter.com/1.1/statuses/user_timeline.json")
    url.query = URI.encode_www_form( filters )

    # Pepare the request
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(url.request_uri)
    req["Authorization"] = "Bearer #{access_token}"

    # Make the request
    request_result = http.request(req)

    # Get the response, parse it and return ir
    result = JSON.parse(request_result.body)
  end

  # Get tweets in the last 6 months from the user.
  # The screen_name has to be a user name of an existing user.
  def get_tweets_last_6_months(screen_name)
    # To not reach the rate limit of the Twitter API, we get 200 (the maximum) tweets in each request
    # until we have the tweets in the last 6 months or older.
    # As we can get older tweets, after the necessary request, we will get rid of that older tweets

    count = 200

    # Get the oldest date
    today = DateTime.now.to_date
    six_month_ago = today.beginning_of_month - 5.month

    # Make the API call to the 200 newest tweets
    params = { :screen_name => screen_name, :count => count }
    tweets = get_user_timeline(params)

    # If we have any results and have no error, check:
    #   - if the last tweet is older than 6 month from now --> We do not need more tweets
    #   - if the last tweet is not older than 6 month from now --> get another 200 tweets and append to the tweet we already have
    # Repeat this proccess until the lasr tweet is older than 6 month from now
    while tweets.any? && !tweets.include?("errors") && tweets.last.include?("created_at") && Date.parse(tweets.last["created_at"]) >= six_month_ago do
      params[:max_id] = tweets.last["id"] - 1
      more_tweets = get_user_timeline(params)
      if !more_tweets.include?("errors")
        tweets += more_tweets
      else
        tweets = more_tweets
      end
    end

    # If have any error, return the error
    result = {};
    if tweets.include?("errors")
      result = tweets
    else
      # Get rid of the tweets older than 6 month from now
      result = [];
      tweets.each do |tweet|
        tweet_date =  Date.parse(tweet["created_at"])
        if tweet_date >=six_month_ago
          result << tweet
        else
          break
        end
      end
    end

    return result
  end

  private

  # This function get the access token for the Twitter API
  def get_access_token
    # API URL
    url = URI.parse("https://api.twitter.com/oauth2/token")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    # Pepare the request
    req = Net::HTTP::Post.new(url.request_uri)
    req["Authorization"] = "Basic #{@api_key_secret_base_64}"
    req["Content-Type"] = "application/x-www-form-urlencoded;charset=UTF-8"
    req.body = "grant_type=client_credentials"

    # Make the request and return the access token
    request_result = http.request(req)
    result = JSON.parse(request_result.body)
    access_token = result['access_token']
  end


  @api_key
  @api_secret
  @api_key_secret_base_64
end
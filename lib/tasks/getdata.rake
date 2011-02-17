task :get_tw_data => :environment do
  require 'rubygems'
  require 'hpricot'
  require 'open-uri'

  include ApplicationHelper

  def get_twitter_data
    @id = (TwitterResult.count > 0) ? TwitterResult.last.id : 1
    url = "http://174.143.243.249:3000/home/twitter_datas?id=#{@id}"
    @xml_data = open(url).read
    @data = Hpricot::XML(@xml_data)
    @total = 0
    (@data/"twitter-restaurant").each do |twitter_restaurant|
      @twitter_result = TwitterResult.new
      @twitter_result.screen_name = (twitter_restaurant.at('screen-name').innerHTML).strip if twitter_restaurant.at('screen-name')
      @twitter_result.tweet_id = (twitter_restaurant.at('tweet-id').innerHTML).strip if twitter_restaurant.at('tweet-id')
      @twitter_result.tweet = (twitter_restaurant.at('tweet').innerHTML).strip if twitter_restaurant.at('tweet')
      @twitter_result.source = CGI.unescapeHTML(twitter_restaurant.at('source').innerHTML).strip if twitter_restaurant.at('source')
      @twitter_result.geo = (twitter_restaurant.at('geo').innerHTML).strip if twitter_restaurant.at('geo')
      @twitter_result.tweet_length = (twitter_restaurant.at('tweet-length').innerHTML).strip if twitter_restaurant.at('tweet-length')
      @twitter_result.has_link = (twitter_restaurant.at('has-link').innerHTML).strip if twitter_restaurant.at('has-link')
      @twitter_result.positive = (twitter_restaurant.at('positive').innerHTML).strip if twitter_restaurant.at('positive')
      @twitter_result.negative = (twitter_restaurant.at('negative').innerHTML).strip if twitter_restaurant.at('negative')
      @twitter_result.spam = (twitter_restaurant.at('spam').innerHTML).strip if twitter_restaurant.at('spam')
      @twitter_result.has_question = (twitter_restaurant.at('has-question').innerHTML).strip if twitter_restaurant.at('has-question')
      @twitter_result.tweet_created = (twitter_restaurant.at('tweet-created').innerHTML).strip if twitter_restaurant.at('tweet-created')
      @twitter_result.keyword = (twitter_restaurant.at('keyword').innerHTML).strip if twitter_restaurant.at('keyword')
      if @twitter_result.save
        @total += 1
      end
    end
    return @total
  end

  print "\n\nRake Task Started for Getting Data From Twitter...\n"
  print "\n#{get_twitter_data} new records added"
  print "\nTwitter Rake Task Completed\n"
  print "\n...\n...\n"
end

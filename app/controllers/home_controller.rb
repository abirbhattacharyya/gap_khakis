class HomeController < ApplicationController
  before_filter :check_login, :only => [:notifications, :analytics]

  def index
    flash.discard
    if logged_in?
      if current_user.profile.nil?
        render :template => "users/profile"
      elsif current_user.products.size <= 0
        render :template => "products/products"
      else
        @notifications = [["profile", current_user.profile.created_at], ["prices", current_user.products.last.created_at]]
        @notifications.sort!{|n1, n2| n2[1] <=> n1[1]}
        render :template => "/home/notifications"
      end
#    else
#      render :template => "users/biz"
    end
  end

  def notifications
    @notifications = [["profile", current_user.profile.created_at], ["prices", current_user.products.last.created_at]]
    @notifications.sort!{|n1, n2| n2[1] <=> n1[1]}
  end

  def analytics
    if request.post?
      @page = params[:page].to_i
    else
      @page = 1
    end
    @size = 5
    @per_page = 1
    @post_pages = (@size.to_f/@per_page).ceil;
    @page =1 if @page.to_i<=0 or @page.to_i > @post_pages
    @titleX = "Time Period"
    @titleY = "#"
    @colors = []

    case @page
      when 1
        @title = "# Came to SYP Capsule"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 2
        @title = "# Started Negotiating"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 3
        @title = "# Reached Pricing Agreement"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and offers.response='accepted' and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and offers.response='accepted' and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 4
        @title = "# Completed a Sale"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and offers.response='paid' and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and offers.response='paid' and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 5
        @title = "$ Completed Sales"
        @titleY = "$"
        @offer_today = Offer.first(:select => "SUM(price) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and offers.response='paid' and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(price) as total", :joins => "INNER JOIN products ON offers.product_id=products.id and offers.response='paid' and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      else
        @title = "# Came to SYP Capsule"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id INNER JOIN wardrobes ON products.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN products ON offers.product_id=products.id INNER JOIN wardrobes ON products.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
    end
  end

  def say_your_price
    if logged_in?
      redirect_to root_path
      return
    end
    if request.post?
      @page = params[:page].to_i
    else
      @page = 1
    end
    @size = Product.count.to_i
    @per_page = 1
    @post_pages = (@size.to_f/@per_page).ceil;
    @page =1 if @page.to_i<=0 or @page.to_i > @post_pages
    @products = Product.all(:limit => "#{@per_page*(@page - 1)}, #{@per_page}")
  end

  def winners
    @results = TwitterResult.all(:order => "id desc", :limit => 100)
  end

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
    flash[:notice] = "#{@total} new records added"
    redirect_to root_path
  end

	def code_generate
    for price_code in PromotionCode::PRICE_CODES
      if PromotionCode.count(:conditions => ["price_point = ?", price_code]) <= 0
        (1..100).each do |i|
          @code = rand_code(16)
          while(1)
            if PromotionCode.find_by_code(@code)
              @code = rand_code(16)
            else
              break;
            end
          end
          PromotionCode.create(:price_point => price_code, :code => @code)
        end
      end
    end
    render :text=> "Done".inspect and return false
  end

end

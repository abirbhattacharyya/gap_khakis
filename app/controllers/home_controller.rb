class HomeController < ApplicationController
  before_filter :check_login, :only => [:notifications, :analytics, :daily_report]

  def index
    flash.discard
    if logged_in?
      if current_user.profile.nil?
        render :template => "users/profile"
      elsif current_user.products.size <= 0
        render :template => "products/products"
      elsif current_user.schedule.nil?
        render :template => "products/schedule"
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

  def my_wardrobes
    @products = current_user.products
  end

  def analytics
    if request.post?
      @page = params[:page].to_i
    else
      @page = 1
    end
    @size = 6
    @per_page = 1
    @post_pages = (@size.to_f/@per_page).ceil;
    @page =1 if @page.to_i<=0 or @page.to_i > @post_pages
    @titleX = "Time Period"
    @titleY = "#"
    @colors = []
    @i = 0

    case @page
      when @i+=1
        @title = "% said= (Yes, No)"
        @titleY = "%"
        @titleX = "response"
        @offer_yes = Offer.count(:conditions => "response LIKE 'accepted' OR response LIKE 'paid'")
        @offer_no = Offer.count(:conditions => "response LIKE 'rejected'")
        total = ((@offer_yes.to_i+@offer_no.to_i) > 0) ? (@offer_yes.to_i+@offer_no.to_i) : 1
        @chart_data1 = [["Yes", (@offer_yes.to_i*100/total)], ["No", (@offer_no.to_i*100/total)]]
      when @i+=1
        @title = "% Of Yes Hit Get Coupon"
        @titleY = "%"
        @titleX = "response"
        @offer_yes = Offer.count(:conditions => "response LIKE 'accepted'")
        @offer_paid = Offer.count(:conditions => "response LIKE 'paid'")
        total = ((@offer_yes.to_i+@offer_paid.to_i) > 0) ? (@offer_yes.to_i+@offer_paid.to_i) : 1
        @chart_data1 = [["coupon", (@offer_paid.to_i*100/total)]]
      when @i+=1
        @title = "# of coupons by day"
        @titleY = "#"
        @titleX = "date"
        @payments = Payment.all(:select => "COUNT(id) as total, Date(created_at) as date", :group => "Date(created_at)")
        @chart_data1 = []
        for payment in @payments
          @chart_data1 << [payment.date.to_date.strftime("%b %d"), payment.total.to_i]
        end
      when @i+=1
        @title = "# Came to SYP Capsule"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :conditions => "Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :conditions => "Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when @i+=1
        @title = "# Started Negotiating"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :conditions => "Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :conditions => "Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when @i+=1
        @title = "# Reached Pricing Agreement"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :conditions => "offers.response='paid' and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :conditions => "offers.response='paid' and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when @i+=1
        @title = "# Completed Sale"
        @offer_today = Payment.first(:select => "COUNT(id) as total", :conditions => "Date(payments.updated_at)='#{Date.today}'")
        @offer_yesterday = Payment.first(:select => "COUNT(id) as total", :conditions => "Date(payments.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when @i+=1
        @title = "$ Completed Sales"
        @titleY = "$"
        @offer_today = Payment.first(:select => "SUM(price) as total", :conditions => "Date(payments.updated_at)='#{Date.today}'")
        @offer_yesterday = Payment.first(:select => "SUM(price) as total", :conditions => "Date(payments.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      else
        @title = "# Came to SYP Capsule"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :conditions => "Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :conditions => "Date(offers.updated_at)='#{Date.today - 1.day}'")
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

    @page_start_num = ((@page - 4) > 0) ? (@page - 4) : 1
    @page_end_num = ((@page_start_num + 8) > @post_pages) ? @post_pages : (@page_start_num + 8)
    @page_start_num = ((@post_pages - @page_end_num) < 8) ? (@page_end_num - 8) : @page_start_num

#    @products = Product.all
  end

  def winners
#    @results = TwitterResult.all(:order => "id desc", :limit => 100)
    @payments = Payment.all(:order => "id desc", :limit => 100)
  end

  def faqs
    
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

  def get_codes
    @files = Dir.glob("dealkat_codes/*")
    print "\n\nPromotion Codes Inserting \n"

    @file = File.open("42315-CROSSBRAND-01_FREE.txt","r")
    @price_point = 0
    print "\nPrice Point: #{@price_point}\n"
    sleep(3)
    @file.each do |line|
      if line
        # render :text=>line and return false
        line.match(/(.*?)\|([a-zA-Z0-9]*)/)
        @keyword = $1
        @keyword2 = $2

        print "\tCode: #{@keyword}\n"
        PromotionCode.create(:price_point => @price_point, :code => @keyword, :used => false)
        # render :text=>@keyword2.inspect and return false
      end
    end
    @file.close

    for file in @files
      @file = File.open(file,"r")
      @price_point = file.split("$")[1].split(".")[0]
      print "\nPrice Point: #{@price_point}\n"
      sleep(3)
      @file.each do |line|
        if line
          # render :text=>line and return false
          line.match(/(.*?)\|([a-zA-Z0-9]*)/)
          @keyword = $1
          @keyword2 = $2

          print "\tCode: #{@keyword}\n"
          PromotionCode.create(:price_point => @price_point, :code => @keyword, :used => false)
          # render :text=>@keyword2.inspect and return false
        end
      end
      @file.close
    end
    print "\nTask Completed\n\n"
    render :text => "Done...".inspect and return false
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

	def send_daily_report
    recipients = "abstartup@gmail.com, dhaval.parikh33@gmail.com"
    @today = Date.today-1.day
    @todays_coupons = Offer.all(:select => "COUNT(id) as total, price", :conditions => ["Date(updated_at) = ? and response LIKE 'paid'", @today], :group => "price")
    @all_coupons = Offer.all(:select => "COUNT(id) as total, price", :conditions => ["response LIKE 'paid'"], :group => "price")

    @analytics_overall = analytics_details('2011-03-02', @today)
    @analytics_today = analytics_details(@today, @today)

    Notification.deliver_dailyreport(recipients,@todays_coupons,@all_coupons,@analytics_today,@analytics_overall,@today)
    flash[:notice] = "Report Sent"
    redirect_to root_path
  end

	def daily_report
    @today = Date.today-1.day
    @todays_coupons = Offer.all(:select => "COUNT(id) as total, price", :conditions => ["Date(updated_at) = ? and response LIKE 'paid'", @today], :group => "price")
    @all_coupons = Offer.all(:select => "COUNT(id) as total, price", :conditions => ["response LIKE 'paid'"], :group => "price")

    @analytics_overall = analytics_details('2011-03-02', @today)
    @analytics_today = analytics_details(@today, @today)
    render :layout => false
  end
end

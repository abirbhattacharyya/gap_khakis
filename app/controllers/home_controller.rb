class HomeController < ApplicationController
  before_filter :check_login, :only => [:notifications, :analytics, :daily_report]

  def index
    flash.discard
    if logged_in?
      if current_user.profile.nil?
        render :template => "users/profile"
      elsif current_user.products.size <= 0
        render :template => "products/product_catalog"
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
#    Notification.deliver_sendcoupon("abstartup@gmail.com")
  end

  def analytics
    @today = Date.today-1.day
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
        @title = "# Of coupons viewed"
        @offers_a = Offer.count(:conditions => ["response <> ?", "expired"])
        @offers_y = Offer.count(:conditions => ["response <> ? and Date(offers.updated_at) = ?", "expired", @today])
        @chart_data1 = [["Yesterday", @offers_y.to_i], ["Cumulative", @offers_a.to_i]]
      when @i+=1
        @title = "Total coupon sales @100% redemption"
        @todays_coupons = Offer.first(:select => "SUM(price) as dollars", :conditions => ["Date(updated_at) = ? and response LIKE 'paid'", @today])
        @all_coupons = Offer.first(:select => "SUM(price) as dollars", :conditions => ["response LIKE 'paid'"])
        @chart_data1 = [["Yesterday", @todays_coupons.dollars.to_i], ["Cumulative", @all_coupons.dollars.to_i]]
      when @i+=1
        @title = "# Coupons <$15"
        @todays_coupons = Offer.count(:conditions => ["Date(updated_at) = ? and response LIKE 'paid' and price < ?", @today, 15])
        @all_coupons = Offer.count(:conditions => ["response LIKE 'paid' and price < ?", 15])
        @chart_data1 = [["Yesterday", @todays_coupons.to_i], ["Cumulative", @all_coupons.to_i]]
      when @i+=1
        @title = "# Coupons $15-29"
        @todays_coupons = Offer.count(:conditions => ["Date(updated_at) = ? and response LIKE 'paid' and (price >= ? and price <= ?)", @today, 15, 29])
        @all_coupons = Offer.count(:conditions => ["response LIKE 'paid' and (price >= ? and price <= ?)", 15, 29])
        @chart_data1 = [["Yesterday", @todays_coupons.to_i], ["Cumulative", @all_coupons.to_i]]
      when @i+=1
        @title = "# Coupons $30-39"
        @todays_coupons = Offer.count(:conditions => ["Date(updated_at) = ? and response LIKE 'paid' and (price >= ? and price <= ?)", @today, 30, 39])
        @all_coupons = Offer.count(:conditions => ["response LIKE 'paid' and (price >= ? and price <= ?)", 30, 39])
        @chart_data1 = [["Yesterday", @todays_coupons.to_i], ["Cumulative", @all_coupons.to_i]]
      when @i+=1
        @title = "# Coupons $40+"
        @todays_coupons = Offer.count(:conditions => ["Date(updated_at) = ? and response LIKE 'paid' and price >= ?", @today, 40])
        @all_coupons = Offer.count(:conditions => ["response LIKE 'paid' and price >= ?", 40])
        @chart_data1 = [["Yesterday", @todays_coupons.to_i], ["Cumulative", @all_coupons.to_i]]
      else
        @title = "# Of coupons viewed"
        @offers_a = Offer.count(:conditions => ["response <> ?", "expired"])
        @offers_y = Offer.count(:conditions => ["response <> ? and Date(offers.updated_at) = ?", "expired", @today])
        @chart_data1 = [["Yesterday", @offers_y.to_i], ["Cumulative", @offers_a.to_i]]
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
  end

  def winners
    @payments = Payment.all(:order => "id desc", :limit => 100)
  end

	def send_daily_report
    recipients = "abstartup@gmail.com, dhaval.parikh33@gmail.com"
#    recipients = "mailtoankitparekh@gmail.com, dhaval.parikh33@gmail.com"
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

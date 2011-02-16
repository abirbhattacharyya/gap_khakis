class HomeController < ApplicationController
  def index
    flash.discard
    if logged_in?
      if current_user.profile.nil?
        render :template => "users/profile"
      elsif current_user.products.size <= 0
        render :template => "users/products"
      else
        @notifications = [["profile", current_user.profile.created_at], ["prices", current_user.products.last.created_at]]
        @notifications.sort!{|n1, n2| n2[1] <=> n1[1]}
        render :template => "/home/notifications"
        #@products = current_user.products
      end
#    else
#      render :template => "users/biz"
    end
  end

  def notifications
    @notifications = [["profile", current_user.profile.created_at], ["prices", current_user.products.last.created_at]]
    @notifications.sort!{|n1, n2| n2[1] <=> n1[1]}
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
#    @payments = Payment.all(:order => "id desc", :limit => 100)
  end

	def code_generate
    for price_code in PromotionCode::PRICE_CODES
      if PromotionCode.count(:conditions => ["price_point = ?", price_code]) <= 0
        (1..10).each do |i|
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

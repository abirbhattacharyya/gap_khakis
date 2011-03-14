class ProductsController < ApplicationController
  before_filter :check_login, :except => [:capsule, :download_pdf, :send_to, :payments, :success, :cancel]

  def product_catalog
    @products = current_user.products
    if request.post?
      if !params[:uploaded_file].blank?
        file = params[:uploaded_file]
        FileUtils.mkdir_p "#{RAILS_ROOT}/public/uploads"

        file_path = "#{RAILS_ROOT}/public/uploads/#{Time.now.to_date}_#{file.original_filename}"
        if file_path.match(/(.*?)[.](.*?)/)
          mime_extension = File.mime_type?(file_path)
        else
            flash[:error]="Hey, files in csv format please"
            return
        end

        if mime_extension.eql? "text/csv" or mime_extension.eql? "text/comma-separated-values"
            if !file.local_path.nil?
               FileUtils.copy_file(file.local_path,"#{file_path}")
            else
               File.open("#{file_path}", "wb") { |f| f.write(file.read) }
            end

            @file=File.open(file_path)
            n=0
            CSV::Reader.parse(File.open("#{file_path}", 'rb')) do |row|
                product = Product.new
                product.user = current_user
                if row.size == 8
                    if row[0]
                      product.style_num = row[0].strip.gsub(/\D+/, '')
                      product.style_description = row[1].to_s
                      product.color_description = row[2].to_s
                      product.first_cost = row[3].gsub(/[^0-9\.]/, '').to_f if row[3]
                      product.ticketed_retail = row[4].gsub(/[^0-9\.]/, '').to_f if row[4]
                      product.margin = row[5].gsub(/[^0-9\.]/, '').to_f if row[5]
                      product.margin_price = row[6].gsub(/[^0-9\.]/, '').to_f if row[6]
                      product.selling_price = row[7].gsub(/[^0-9\.]/, '').to_f if row[7]
                    end
                    product.errors.add_to_base("Hey, regular price must be atleast 1") if product.first_cost.to_i < 1

                    if(product.errors.empty? and product.valid?)
                        product.save
                        product.update_attribute(:image_url, "/products/#{product.id}.png")
                        n=n+1
                        GC.start if n%50==0
                    end
                end
            end
            if n==0
              flash[:notice] = "Uploaded file has the wrong columns. Plz. fix & re-upload"
            else
              flash[:notice]="Uploaded your file!"
              redirect_to root_path
            end
        else
            flash[:error]="Plz. upload a file with the correct format"
        end
      else
        flash[:error]="Hey, please upload csv file"
      end
    end
  end

  def payments
    if request.post?
      if params[:payment]
        @payment = Payment.find(params[:id])
        if @payment.update_attributes(params[:payment])
          Notification.deliver_sendcoupon(@payment.email, @payment)
          flash[:notice] = "Emailed coupon. Will not use to market to you."
          redirect_to say_your_price_path
          return
        else
          @payment.email = nil
          flash[:error]= "Hi, please enter a valid email address"
          return
        end
      else
        @offer = Offer.find_by_id(params[:id].to_i)
        if @offer.nil?
          redirect_to root_path
          return
        end
      end

      @payment = @offer.payment
      if @payment.nil?
        @promotion_code = PromotionCode.first(:conditions => ["price_point = ? and used = 0", @offer.price])
        if @promotion_code
          @payment = Payment.create(:offer_id => @offer.id, :promotion_code_id => @promotion_code.id)
          @payment.update_attributes(:expiry => @payment.new_expiry_date)
          @promotion_code.update_attribute(:used, true) unless [31,34,39].include? @offer.price.to_i
          @offer.update_attribute(:response, "paid")
        else
          flash[:notice] = "Sorry promotions over. Try again later"
          redirect_to root_path
        end
      end
    else
      redirect_to root_path
    end
  end

  def download_emails
    payments = Payment.find(:all, :conditions => "email IS NOT NULL and email <> ''")
    csv_string = FasterCSV.generate do |csv|
      csv << ["Style #", "Email"]
      payments.each do |payment|
        csv << [payment.offer.product.style_num, payment.email]
      end
    end
    send_data csv_string, :filename => 'emails.csv', :type => 'text/csv', :disposition => 'attachment'
  end

  def download_pdf
    if params[:id]
      @payment = Payment.find_by_id(params[:id])
      if @payment.nil?
        redirect_to root_path
        return
      end
      output= render_to_string :partial => "partials/pdf_letter", :object => @payment
      pdf = PDF::Writer.new
      pdf.add_image_from_file("#{Rails.root}/public/images/logo-gap.jpg", 35, 730, 50, 50)
      pdf.text output
      send_data pdf.render, :filename => "mypricecoupon.pdf", :type => "application/pdf"
    else
      redirect_to root_path
    end
  end

  def capsule
    if params[:id]
      @product = Product.find_by_id(params[:id])
      if @product.nil?
        redirect_to root_path
        return
      end
#          avg_offer = @product.offers.last(:select => "AVG(price) as avg_price", :conditions => ["response = ?", 'paid'])
#          render :text => avg_offer.avg_price.inspect and return false
#                        render :text => (Offer.min_offers_of(30).count >= (Offer.paid_offers.count*0.02).ceil) and return false
      offer_token = (session[:_csrf_token] ||= ActiveSupport::SecureRandom.base64(32))

      @last_offer = @product.offers.last(:conditions => ["ip = ? and token = ?", request.remote_ip, offer_token])
      if request.post?
        if @last_offer and @last_offer.accepted?
          return
        end
        if params[:submit_button]
          submit = params[:submit_button].strip.downcase
          if ["yes", "no"].include? submit
            if submit == "no"
              @last_offer.update_attribute(:response, "rejected")
              flash[:error] = "Sorry we can't make a deal right now. Try again later?"
            elsif submit == "yes"
              @last_offer.update_attribute(:response, "accepted")
              flash[:notice] = (@last_offer.price == 0) ? "Cool! Congrats! you won free Gap khakis. Share with facebook /twitter friends!" : "Cool, come on down to the store!"
            end
            for offer in @product.offers.all(:conditions => ["ip = ? and token = ? and id < ? and (response IS NULL OR response LIKE 'counter')", request.remote_ip, offer_token, @last_offer.id])
              offer.update_attribute(:response, "expired") unless ["paid", "accepted", "rejected"].include? offer.response
            end
            return
          end
        end
        price = params[:price].to_i
        if price <= 0
            flash[:error] = "Hi, please enter a non-zero number and we can play"
        else
          reg_price = ((@product.ticketed_retail == 49.5) ? 45 : 59)
          avg_offer = @product.offers.last(:select => "AVG(price) as avg_price", :conditions => ["response = ?", 'paid'])

          if @last_offer and @last_offer.counter?
              @offer = @product.offers.last(:conditions => ["ip = ? and token = ? and response IS NULL", request.remote_ip, offer_token])
              if @offer
                if price >= @last_offer.price
                  @last_offer.update_attribute(:response, "accepted")
                  flash[:notice] = "Cool, come on down to the store!"
                  return
                end
                if(price > @offer.price)
                    @price_codes = []
                    if avg_offer.avg_price.nil?
                      for price_code in @product.new_price_points
                        @price_codes << price_code if(price_code > @offer.price and price_code < @last_offer.price)
                      end
                    else
                      if price < @product.target_price
                        if avg_offer.avg_price.to_f < @product.target_price
                          for price_code in @product.new_price_points
                            @price_codes << price_code if(price_code > @offer.price and price_code < @last_offer.price)
                          end
                        else
                          for price_code in @product.min_price_points
                            if(price_code > @offer.price and price_code < @last_offer.price)
                              if(Offer.min_offers_of(30).count >= (Offer.paid_offers.count*0.02).ceil)
                                @price_codes << price_code if price_code >= 30
                              else
                                @price_codes << price_code
                              end
                            end
                          end
                        end
                      else
                        for price_code in @product.new_price_points
                          @price_codes << price_code if(price_code > @offer.price and price_code < @last_offer.price)
                        end
                      end
                    end
                    @offer.update_attributes(:price => price, :counter => (@offer.counter + 1))
                    if @price_codes.size > 0
                      @new_offer = @price_codes[rand(999)%@price_codes.size]
                      if @new_offer == @last_offer.price or @new_offer <= price
                        @last_offer.update_attributes(:price => @new_offer, :response => "accepted")
                      else
                        @last_offer.update_attributes(:price => @new_offer, :counter => (@last_offer.counter + 1))
                        if((rand(999)%2) == 1)
                          @last_offer.update_attributes(:response => "last")
                        end
                      end
                    else
                      @last_offer.update_attributes(:response => "last")
                    end
                else
                    flash[:notice] = "Hey, please enter an offer greater than the last one!"
                    return
                end
              else
                return
              end
          else
              @offer = Offer.new(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => price, :counter => 1)
              @offer.save
              @last_offer = @product.offers.last(:conditions => ["ip = ? and token = ?", request.remote_ip, offer_token])
              
              if(price <= @product.min_price)
                  if avg_offer.avg_price
                    if avg_offer.avg_price.to_f >= @product.target_price
                      @price_codes = []
                      for price_code in @product.min_price_points
                        if(price_code > price)
                          if(Offer.min_offers_of(30).count >= (Offer.paid_offers.count*0.02).ceil)
                            @price_codes << price_code if price_code >= 30
                          else
                            @price_codes << price_code
                          end
                        end
                      end
                      @new_offer = @price_codes[rand(999)%@price_codes.size]
                      if @new_offer == @product.target_price
                        Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "last", :counter => 1)
                        flash[:notice] = "Hey, the best we can do is $#{@new_offer}. Deal?"
                      elsif price >= @new_offer
                        Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "accepted", :counter => 1)
                        flash[:notice] = "Cool, come on down to the store!"
                      else
                        Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "counter", :counter => 1)
                        flash[:notice] = "Hi, we can do $#{@new_offer}. Deal?"
                      end
#                      Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "counter", :counter => 1)
#                      flash[:notice] = "Hi, we can do $#{@new_offer}. Deal?"
                    else
                      @new_offer = ((@product.ticketed_retail == 49.5) ? 45 : 59)
                      Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "last", :counter => 1)
                      flash[:notice] = "Hi, $#{price} is too low. How about $#{@new_offer}?"
                    end
                  else
                    @new_offer = ((@product.ticketed_retail == 49.5) ? 45 : 59)
                    Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "last", :counter => 1)
                    flash[:notice] = "Hi, $#{price} is too low. How about $#{@new_offer}?"
                  end
              elsif(price >= reg_price)
                  @new_offer = ((@product.ticketed_retail == 49.5) ? 45 : 55)
                  Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "counter", :counter => 1)
                  @counter_offer = @product.offers.last(:conditions => ["ip = ? and token =? and response = ?", request.remote_ip, offer_token, 'counter'])
                  for offer in @product.offers.all(:conditions => ["ip = ? and token = ? and id <= ? and (response IS NULL OR response LIKE 'counter')", request.remote_ip, offer_token, @offer.id])
                    offer.update_attribute(:response, "expired") unless ["paid", "accepted", "rejected"].include? offer.response
                  end
                  @counter_offer.update_attribute(:response, "accepted")
                  if price >= @product.ticketed_retail
                    flash[:notice] = "Hey, don't overspend. Yours for only $#{@new_offer}"
                  else
                    flash[:notice] = "Cool, come on down to the store!"
                  end
              else
                  if avg_offer.avg_price.nil?
                    @new_offer = @product.new_price_points[rand(999)%@product.new_price_points.size]
                  else
                    @price_codes = []
                    if price < @product.target_price
                      if avg_offer.avg_price.to_f < @product.target_price
                        for price_code in @product.new_price_points
                          @price_codes << price_code
                        end
                      else
                        if(Offer.min_offers_of(30).count >= (Offer.paid_offers.count*0.02).ceil)
                          @price_codes << @product.target_price
                        else
                          for price_code in @product.min_price_points
                            if(price_code >= @last_offer.price)
                              @price_codes << price_code
                            end
                          end
                        end
#                        if(Offer.min_offers_of(30).count >= (Offer.paid_offers.count*0.02).ceil)
#                          @price_codes << @product.target_price
#                        else
#                          for price_code in @product.min_price_points
#                            if(price_code >= @last_offer.price)
#                              @price_codes << price_code
#                            end
#                          end
#                        end
                        for price_code in @product.min_price_points
                          if(price_code > price)
                            if(Offer.min_offers_of(30).count >= (Offer.paid_offers.count*0.02).ceil)
                              @price_codes << price_code if price_code >= 30
                            else
                              @price_codes << price_code
                            end
                          end
                        end
                      end
                    else
                      for price_code in @product.new_price_points
                        @price_codes << price_code if(price_code > price)
                      end
                    end
                    @new_offer = @price_codes[rand(999)%@price_codes.size]
                  end
                  if @new_offer == @product.target_price
                    Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "last", :counter => 1)
                    flash[:notice] = "Hey, the best we can do is $#{@new_offer}. Deal?"
                  elsif price >= @new_offer
                    Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "accepted", :counter => 1)
                    flash[:notice] = "Cool, come on down to the store!"
                  else
                    Offer.create(:ip => request.remote_ip, :token => offer_token, :product_id => @product.id, :price => @new_offer, :response => "counter", :counter => 1)
                    flash[:notice] = "Hi, we can do $#{@new_offer}. Deal?"
                  end
              end
              return
          end
          @last_offer = @product.offers.last(:conditions => ["ip = ? and token = ?", request.remote_ip, offer_token])
          if @last_offer.last?
            flash[:notice] = "Hey, the best we can do is $#{@last_offer.price.ceil.to_i}. Deal?"
          elsif @last_offer.accepted?
            flash[:notice] = "Cool, come on down to the store!"
          else
            flash[:notice] = "Hi, we can do #{(@last_offer.price.ceil.to_i > 0) ? "$#{@last_offer.price.ceil.to_i}" : "Free of cost"}. Deal?"
          end
          return
        end
      end
    end
  end
end

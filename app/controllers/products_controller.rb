class ProductsController < ApplicationController
  before_filter :check_login, :except => [:capsule, :download_pdf, :send_to, :payments, :success, :cancel]

  def products
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
#        render :text => mime_extension.inspect and return false

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

                if row.size == 10
                    if row[0]
                      product.style_num = row[0].strip.gsub(/\D+/, '')
                      product.style_num_full = row[1].strip.gsub(/\D+/, '')
                      product.style_description = row[2].to_s
                      product.color_description = row[3].to_s
                      product.first_cost = row[4].gsub(/[^0-9\.]/, '').to_f if row[4]
                      product.ellc = row[5].gsub(/[^0-9\.]/, '').to_f if row[5]
                      product.ticketed_retail = row[6].gsub(/[^0-9\.]/, '').to_f if row[6]
                      product.ticketed_GM = row[7].gsub(/[^0-9\.]/, '').to_f if row[7]
                      product.target_GM = row[8].gsub(/[^0-9\.]/, '').to_f if row[8]
                      product.image_url = row[9].to_s
                    end

                    product.errors.add_to_base("Hey, regular price must be atleast 1") if product.first_cost.to_i < 1
                    if product.image_url and !product.image_url.strip.blank?
                        pic_url = product.image_url + " "
                        if pic_url.match("(.*?)//(.*?)/(.*?) ")
                            site = $2
                            url = "/" + $3
                            ext = url.downcase.reverse[0..url.reverse.index("\.")]

                            if(ext.reverse.to_s.eql?("\.png") or ext.reverse.to_s.eql?("\.jpg") or ext.reverse.to_s.eql?("\.jpeg") or ext.reverse.to_s.eql?("\.gif"))
                                #TODO Nothing
                            else
                                product.errors.add(:image_url ,"^Hey, photo url should be of png, jpg or gif")
                            end
                        end
                    end

                    if(product.errors.empty? and product.valid?)
                        product.save
                        if(product.image_url and !product.image_url.strip.blank?)
                            FileUtils.mkdir_p "#{RAILS_ROOT}/public/products"

                            Net::HTTP.start("#{site}") { |http|
                              resp = http.get("#{url}")
                              open("public/products/#{product.id}#{ext.reverse.to_s}", "wb") { |file|
                                file.write(resp.body)
                               }
                            }
                            product.update_attribute(:image_url, "/products/#{product.id}#{ext.reverse.to_s}")
                        end
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
          if [0,1,5].include? @payment.offer.price
            @payments = Payment.find_all_by_email(@payment.email)
            @found = false
            if @payments.size > 1
              for payment in @payments
                if((payment.id != @payment.id) and (payment.offer.price == @payment.offer.price))
                  @found = true
                  break;
                end
              end
            end
            if @found == true
              if @payment.offer.product.ticketed_retail.to_f == 49.5
                @payment.offer.update_attribute(:price, 30)
              else
                @payment.offer.update_attribute(:price, 35)
              end
              @payment.promotion_code.update_attribute(:used, false)
              @promotion_code = PromotionCode.first(:conditions => ["price_point = ? and used = 0", @payment.offer.price])
              @payment.update_attribute(:promotion_code_id, @promotion_code.id)
              @promotion_code.update_attribute(:used, true)
              flash[:notice] = "hey only 1 free/$1/$5 per email"
            end
          end
          Notification.deliver_sendcoupon(@payment.email, @payment)
          return
        else
          @payment.email = nil
          flash[:error]= "Hey, please enter a valid email address"
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
          @promotion_code.update_attribute(:used, true)
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
        csv << [payment.offer.product.style_num_full, payment.email]
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

  def schedule
    if request.post?
      Schedule.create(:user_id => current_user.id, :start_date => params[:start_date].to_date, :end_date => params[:end_date].to_date)
      redirect_to root_path
    end
  end

  def send_to
    @product = Product.find_by_id(params[:id])
    redirect_to root_path if @product.nil?

    if params[:emails]
      @emails = params[:emails]
      @message = params[:message]
      if check_emails(@emails)
        @message += "<br />hey check out http://dealkat.com and use myprice at gap stores for $35 khakis"
        name = (params[:name].nil? or params[:name].blank?) ? 'Someone' : params[:name]
        recipient = @emails

        Notification.deliver_sendto(recipient,@product,name,@message)
        flash[:notice]= "Yeah! Email sent!"
        redirect_to capsule_path(@product.id)
      else
        flash[:error]= "Hey, please enter a valid email address"
      end
    end
  end

  def capsule
    if params[:id]
      @product = Product.find_by_id(params[:id])
      if @product.nil?
        redirect_to root_path
        return
      end
      @last_offer = @product.offers.last(:conditions => ["ip = ?", request.remote_ip])
#      render :text => "Under Maintainance.......Coming Soon........" and return false
      if request.post?
        if @last_offer and @last_offer.accepted?
          return
        end
        if params[:submit_button]
          submit = params[:submit_button].strip.downcase
          if ["yes", "no"].include? submit
            if submit == "no"
              min_price = (@product.ticketed_retail == 49.5) ? 15 : 18
              @offer = @product.offers.last(:conditions => ["ip = ? and response IS NULL", request.remote_ip])
              if @offer
                if((@offer.price > min_price) and ((rand(999)%2) == 1))
                    @price_codes = []
                    if(@product.ticketed_retail == 49.5)
                      for price_code in PromotionCode::PRICE_CODES_50
                        @price_codes << price_code if(price_code > @offer.price and price_code < @last_offer.price)
                      end
                    else
                      for price_code in PromotionCode::PRICE_CODES_60
                        @price_codes << price_code if(price_code > @offer.price and price_code < @last_offer.price)
                      end
                    end
                    if @price_codes.size > 0
                      @new_offer = @price_codes[rand(999)%@price_codes.size]
                      @last_offer.update_attributes(:price => @new_offer, :counter => (@last_offer.counter + 1))
                      flash[:notice] = "Hi, we are so close, let's make a deal at $#{@new_offer}"
                      return
                    end
                end
              end
              @last_offer.update_attribute(:response, "rejected")
              flash[:error] = "Sorry we can't make a deal right now. Try again later?"
            elsif submit == "yes"
              @last_offer.update_attribute(:response, "accepted")
              flash[:notice] = "Cool, come on down to the store!"
            end
            for offer in @product.offers.all(:conditions => ["ip = (?) and id < ? and (response IS NULL OR response LIKE 'counter')", request.remote_ip, @last_offer.id])
              offer.update_attribute(:response, "expired") unless ["paid", "accepted", "rejected"].include? offer.response
            end
            return
          end
        end
        price = params[:price].to_i
        if price <= 0
          flash[:error] = "Hi, please enter a non-zero number and we can play"
        else
          if @last_offer and @last_offer.counter?
            return
          else
            @offer = Offer.new(:ip => request.remote_ip, :product_id => @product.id, :price => price, :counter => 1)
            @offer.save
          end
#          reg_price = @product.ticketed_retail
          reg_price = ((@product.ticketed_retail == 49.5) ? 45 : 59)
          target_price = (@product.ticketed_retail == 49.5) ? 30 : 35
          min_price = (@product.ticketed_retail == 49.5) ? 15 : 18

          if(price <= min_price)
              @new_offer = ((@product.ticketed_retail == 49.5) ? 45 : 59)
              Offer.create(:ip => request.remote_ip, :product_id => @product.id, :price => @new_offer, :response => "counter", :counter => 1)
              flash[:notice] = "Hi $#{price} is too low. How about $#{@new_offer}"
          elsif(price >= reg_price)
              @new_offer = ((@product.ticketed_retail == 49.5) ? 45 : 55)
              Offer.create(:ip => request.remote_ip, :product_id => @product.id, :price => @new_offer, :response => "counter", :counter => 1)
              @counter_offer = @product.offers.last(:conditions => ["ip = ? and response = ?", request.remote_ip, 'counter'])
              for offer in @product.offers.all(:conditions => ["ip = (?) and id <= ? and (response IS NULL OR response LIKE 'counter')", request.remote_ip, @offer.id])
                offer.update_attribute(:response, "expired") unless ["paid", "accepted", "rejected"].include? offer.response
              end
              @counter_offer.update_attribute(:response, "accepted")
              flash[:notice] = "Cool, come on down to the store!"
          else
              if price > target_price
                @price_codes = []
                if(@product.ticketed_retail == 49.5)
                  for price_code in PromotionCode::PRICE_CODES_50
                    @price_codes << price_code if price_code > price
                  end
                else
                  for price_code in PromotionCode::PRICE_CODES_60
                    @price_codes << price_code if price_code > price
                  end
                end
                @new_offer = @price_codes[rand(999)%@price_codes.size]
              else
                if(@product.ticketed_retail == 49.5)
                  @new_offer = PromotionCode::PRICE_CODES_50[rand(999)%PromotionCode::PRICE_CODES_50.size]
                else
                  @new_offer = PromotionCode::PRICE_CODES_60[rand(999)%PromotionCode::PRICE_CODES_60.size]
                end
              end
              Offer.create(:ip => request.remote_ip, :product_id => @product.id, :price => @new_offer, :response => "counter", :counter => 1)
              flash[:notice] = "Hi, we are so close, let's make a deal at $#{@new_offer}"
          end
          @last_offer = @product.offers.last(:conditions => ["ip = ?", request.remote_ip])
        end
      end
    else
      redirect_to root_path
    end
  end
end

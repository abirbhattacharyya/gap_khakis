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
#          redirect_to root_path
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
      send_data pdf.render, :filename => "storemyprices.pdf", :type => "application/pdf"
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
      @accepted_offer = @product.offers.last(:conditions => ["ip = ? and (response = ? OR response = ?)", request.remote_ip, 'accepted', 'paid'])
      @accepted = (@accepted_offer.nil? ? false: true)
      @counter_offer = @product.offers.last(:conditions => ["ip = ? and response = ?", request.remote_ip, 'counter'])
      @new_price = @counter_offer.price if @counter_offer
      @counter = (@counter_offer ? true : false)
      @last_offer = (@counter_offer ? true : false)
      if request.post?
        if @accepted_offer
          return
        end

        @offer = @product.offers.last(:conditions => ["ip = (?) and (response IS NULL OR response = ?)", request.remote_ip, "counter"])
        if params[:submit_button]
          submit = params[:submit_button].strip.downcase
          if ["yes", "no"].include? submit
              if @offer
                for offer in @product.offers.all(:conditions => ["ip = (?) and id <= ?", request.remote_ip, @offer.id])
                  offer.update_attribute(:response, "expired") unless ["paid", "accepted"].include? offer.response
                end
              end
              if submit == "no"
                if @counter_offer
                  @counter_offer.update_attribute(:response, "rejected")
                  flash[:error] = "Hey, Sorry we can't agree on a deal."
                end
              elsif submit == "yes"
                if @counter_offer
                  @counter_offer.update_attribute(:response, "accepted")
                  flash[:notice] = "Cool, come on down to the store!"
                end
                @accepted = true
                @accepted_offer = @product.offers.last(:conditions => ["ip = ? and (response = ? OR response = ?)", request.remote_ip, 'accepted', 'paid'])
                if @accepted_offer.nil?
                  redirect_to capsule_path(@product.id)
                end
              end
              @counter = false
              return
          end
        end
        price = params[:price].to_i
        if price.to_i <= 0
          flash[:error] = "Hey, please don't enter a 0 or blank offer. Thanks."
        else
          reg_price = @product.ticketed_retail.ceil
          if @offer
            return
          else
            @offer = Offer.new(:ip => request.remote_ip, :product_id => @product.id, :price => price, :counter => 1)
            @offer.save
          end
          if(Offer.accepted_offers.count.to_i == 0)
            if @product.ticketed_retail.to_f == 49.5
              @new_offer = 30
            else
              @new_offer = 35
            end
          else
            divider = (100)**(Offer.accepted_offers.count.to_s.size-1)
            modulo = Offer.accepted_offers.count.to_i/divider
            remainder = (divider == 1) ? modulo : Offer.accepted_offers.count.to_i-(divider*modulo)
            if(remainder == 96)
              @new_offer = 0
            elsif(remainder == 97)
              @new_offer = 1
            elsif(remainder == 98)
              @new_offer = 5
            elsif(remainder == 99)
              @new_offer = 40
            else
              if @product.ticketed_retail.to_f == 49.5
                @new_offer = 30
              else
                @new_offer = 35
              end
            end
          end
          Offer.create(:ip => request.remote_ip, :product_id => @product.id, :price => @new_offer, :response => "counter", :counter => 1)
          flash[:notice] = "Hey, the best we can do is #{(@new_offer > 0) ? "$#{@new_offer.ceil}" : "Free of cost"}. Deal?"
          @last_offer = true

          target_price = (@product.ticketed_retail == 49.5) ? 30 : 35
          price_point = (@product.ticketed_retail == 49.5) ? 45 : 59
          if(price.to_i >= target_price)
            @counter_offer = @product.offers.last(:conditions => ["ip = ? and response = ?", request.remote_ip, 'counter'])
            for offer in @product.offers.all(:conditions => ["ip = (?) and id <= ?", request.remote_ip, @offer.id])
              offer.update_attribute(:response, "expired") unless ["paid", "accepted"].include? offer.response
            end
            if [96,97,98,99].include? remainder
            else
              if(price.to_i >= reg_price)
                @counter_offer.update_attribute(:price, price_point)
              else
                @promotion_code = PromotionCode.first(:conditions => ["price_point = ? and used = 0", price.to_i])
                if @promotion_code.nil?
                  @promotion_code = PromotionCode.last(:conditions => ["price_point < ? and used = 0", price.to_i])
                  flash[:notice] = "Hey, why not pay a bit lower? Yours for $#{@counter_offer.price}"
                else
                  flash[:notice] = "Cool, come on down to the store!"
                end
                @counter_offer.update_attribute(:price, @promotion_code.price_point)
              end
            end
            @counter_offer.update_attribute(:response, "accepted")
            @accepted = true
            return
          end


          if @accepted == true
            for offer in @product.offers.all(:conditions => ["ip = (?) and id <= ?", request.remote_ip, @offer.id])
              offer.update_attribute(:response, "expired") unless ['paid', 'accepted'].include? offer.response
            end
            if @offer.counter > 1
              @offer.update_attribute(:response, "accepted")
            elsif @counter_offer
              @counter_offer.update_attribute(:response, "accepted")
            else
              @offer.update_attribute(:response, "accepted")
            end
            @accepted_offer = @product.offers.last(:conditions => ["ip = (?) and (response = ? OR response = ?)", request.remote_ip, 'accepted', 'paid'])
            if(price.to_i >= reg_price)
              msg = "Hey, don't overspend. Buy it @ a special discount of $#{@accepted_offer.price.ceil}"
            else
              msg = "You won! Congratulations!"
            end
            flash[:error] = msg
          end
        end
      end
    else
      redirect_to root_path
    end
  end
end

class ProductsController < ApplicationController
  before_filter :check_login, :except => [:capsule, :send_to, :payments, :success, :cancel]

  def products
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
    if params[:id]
      @offer = Offer.find_by_id(params[:id])
      redirect_to root_path if @offer.nil?

      @payment = @offer.payment
      if @payment.nil?
        @promotion_code = PromotionCode.last(:order => "rand()")
        @payment = Payment.create(:offer_id => @offer.id, :promotion_code_id => @promotion_code.id)
        @promotion_code.update_attribute(:used, true)
      end
    else
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
            name = (params[:name].nil? or params[:name].blank?) ? 'Someone' : params[:name]
            recipient = @emails

            Notification.deliver_sendto(recipient,@product,name,params[:message])
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
      @accepted_offer = @product.offers.last(:conditions => ["ip = (?) and response = (?)", request.remote_ip, 'accepted'])
      @accepted = (@accepted_offer.nil? ? false: true)
      @counter_offer = @product.offers.last(:conditions => ["ip = (?) and response = (?)", request.remote_ip, 'counter'])
      @new_price = @counter_offer.price if @counter_offer
      @counter = (@counter_offer ? true : false)
      @last_offer = (@counter_offer ? true : false)
      if request.post?
        @offer = @product.offers.last(:conditions => ["ip = (?) and response IS NULL", request.remote_ip])
        if params[:submit_button]
          submit = params[:submit_button].strip.downcase
          if submit == "no"
              if @offer
                for offer in @product.offers.all(:conditions => ["ip = (?) and response <> (?) and id <= (?)", request.remote_ip, 'accepted', @offer.id])
                  offer.update_attribute(:response, "expired") if offer.response != "paid" and offer.response != "accepted"
                end
              end
              if @counter_offer
                @counter_offer.update_attribute(:response, "rejected")
              end
              @counter = false
              flash[:error] = "Hey, sorry it didn't work out."
              return
          elsif submit == "yes"
              if @offer
                for offer in @product.offers.all(:conditions => ["ip = (?) and id <= (?)", request.remote_ip, @offer.id])
                  offer.update_attribute(:response, "expired") if offer.response != "paid" and offer.response != "accepted"
                end
                flash[:error] = "Cool, the wardrobe is yours for $#{@offer.price.ceil}"
              end
              if @counter_offer
                @counter_offer.update_attribute(:response, "accepted")
                flash[:error] = "Cool, the wardrobe is yours for $#{@counter_offer.price.ceil}"
              end
              @accepted = true
              @accepted_offer = @product.offers.last(:conditions => ["ip = (?) and response = (?)", request.remote_ip, 'accepted'])
              if @accepted_offer.nil?
                flash[:error] = ""
                redirect_to capsule_path(@product.id)
              end
              return
          end
        end
        price = params[:price].to_i
        if price.to_i <= 0
          flash[:error] = "Hey you can't get something for nothing"
        else
          reg_price = @product.ticketed_retail.ceil
          min_price = (@product.ticketed_retail.to_f * (0.40)).ceil
          if @offer
            if price > @offer.price
              @offer.update_attribute(:price, price)
              @offer.update_attribute(:counter, @offer.counter+1)
            else
              flash[:error] = "Your offer=$#{price} is rejected for the wardrobe!"
              for offer in @product.offers.all(:conditions => ["ip = (?) and id <= ?", request.remote_ip, @offer.id])
                  offer.update_attribute(:response, "expired") unless ['paid', 'accepted'].include? offer.response
              end
              @offer.update_attribute(:response, "rejected")
              return
            end
          else
            @offer = Offer.new(:ip => request.remote_ip, :product_id => @product.id, :price => price, :counter => 1)
            @offer.save
          end
          percent = (100-(rand(40-25) + 25).to_f)/100
          if(price.to_i >= min_price)
              if(price.to_i >= (0.60*reg_price.to_f).ceil)
                @accepted = true
              else
                Offer.create(:ip => request.remote_ip, :product_id => @product.id, :price => (percent*reg_price.to_f).ceil, :response => "counter", :counter => 1)
                @counter_offer = @product.offers.last(:conditions => ["ip = (?) and response = (?)", request.remote_ip, 'counter'])
                if @counter_offer
                  flash[:notice] = "Hey, the best we can do is $#{@counter_offer.price.ceil}. Deal?"
                  @new_price = @counter_offer.price.ceil
                  @last_offer = true
                end
                @counter = true
              end
          else
              flash[:error] = "Hey, the regular wardrobe price=$#{reg_price.ceil}. Make another offer?"
              for offer in @product.offers.all(:conditions => ["ip = (?) and id <= ?", request.remote_ip, @offer.id])
                  offer.update_attribute(:response, "expired") unless ['paid', 'accepted'].include? offer.response
              end
              @offer.update_attribute(:response, "rejected")
              return
          end

          if @accepted == true
            for offer in @product.offers.all(:conditions => ["ip = (?) and id <= ?", request.remote_ip, @offer.id])
                offer.update_attribute(:response, "expired") unless ['paid', 'accepted'].include? offer.response
            end
            if(price.to_i >= reg_price)
              @offer.update_attribute(:price, (reg_price*0.90))
            end
            if @offer.counter > 1
              @offer.update_attribute(:response, "accepted")
            elsif @counter_offer
              @counter_offer.update_attribute(:response, "accepted")
            else
              @offer.update_attribute(:response, "accepted")
            end
            @accepted_offer = @product.offers.last(:conditions => ["ip = (?) and response = (?)", request.remote_ip, 'accepted'])
            if(price.to_i >= reg_price)
              msg = "Hey, don't overspend. The wardrobe is yours at a discount for $#{@accepted_offer.price.ceil}"
            else
              msg = "Your offer=$#{@accepted_offer.price.ceil} is accepted for the wardrobe!"
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

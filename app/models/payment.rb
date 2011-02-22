class Payment < ActiveRecord::Base
  belongs_to :offer
  belongs_to :promotion_code

  validates_format_of :email, :if => :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :update

  def self.total_accepted_price(p1, p2)
    Payment.first(:joins => "INNER JOIN offers ON offers.id=payments.offer_id INNER JOIN products ON products.id=offers.product_id", :select => "SUM(products.ticketed_retail) as total", :conditions => ["offers.price = ? OR offers.price = ?", p1, p2]).total
  end

  def self.total_prices
    Payment.first(:joins => "INNER JOIN offers ON offers.id=payments.offer_id INNER JOIN products ON products.id=offers.product_id", :select => "SUM(products.ticketed_retail) as total").total
  end
end

class Offer < ActiveRecord::Base
  belongs_to :product
  has_one :payment

  PRICE_POINT = ["free", "$5", "40%"]
end

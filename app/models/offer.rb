class Offer < ActiveRecord::Base
  belongs_to :product
  has_one :payment

  PRICE_POINT = ["free", "$5", "40%"]

  named_scope :accepted_offers, {:conditions => ["response LIKE ? OR response LIKE ? OR response LIKE ?", "paid", "accepted", "counter"]}
end

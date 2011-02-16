class PromotionCode < ActiveRecord::Base
  has_one :payment

  PRICE_CODES = [0, 1, 5, 7, 10, 11, 15, 20, 22, 25, 30, 35, 40, 45, 50, 55, 59]
end

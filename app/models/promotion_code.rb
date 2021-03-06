class PromotionCode < ActiveRecord::Base
  has_one :payment

  PRICE_CODES = [0,1,5,7,10,11,15,20,22,25,30,31,34,35,37,39,40,41,44,45,47,49,50,52,55,59]

  PRICE_CODES_50 = [30,31,34,35,37,39,40,41,44,45,47,49]
  PRICE_CODES_60 = [35,37,39,40,41,44,45,47,49,50,52,55,59]
end

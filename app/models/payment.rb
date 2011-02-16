class Payment < ActiveRecord::Base
  belongs_to :offer
  belongs_to :promotion_code
end

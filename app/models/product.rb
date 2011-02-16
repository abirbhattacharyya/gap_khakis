class Product < ActiveRecord::Base
  belongs_to :user
  has_many :offers

  validates_uniqueness_of :style_num_full, :scope => [:user_id]
end

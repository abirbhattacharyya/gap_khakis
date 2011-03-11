class Payment < ActiveRecord::Base
  belongs_to :offer
  belongs_to :promotion_code

  validates_format_of :email, :if => :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  def new_expiry_date
    @dates = ["2011-03-31", (self.created_at + 2.week), (self.created_at + 1.week)]
    return @dates[rand(99)%@dates.size]
  end
end

class Profile < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :name, :address, :phone, :twitter, :facebook_url, :company_url
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :message => "^Hey, incorrect email"

  def twitter_url
    if self.twitter
      "http://twitter.com/" + self.twitter
    end
  end
end

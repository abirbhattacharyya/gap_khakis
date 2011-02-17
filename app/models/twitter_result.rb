class TwitterResult < ActiveRecord::Base
	validates_uniqueness_of :tweet, :scope => [:tweet_created, :screen_name]

  named_scope :get_keyword_data, (lambda do |keyword, limit|
    {:conditions => ["tweet RLIKE (?)", keyword], :limit => limit.to_i, :order => "tweet_created DESC"}
  end)
end

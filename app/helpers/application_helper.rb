# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include GoogleVisualization
  include ActionView::Helpers::TextHelper

  def rand_code(limit)
    str1 = ("a".."z").to_a + ("0".."9").to_a
    ary1 = []
    (1..limit).each { |i| ary1 << str1[rand(999)%str1.length] }
    return ary1.to_s
  end

  def plural(num, text)
    pluralize(num, text)
  end

  def analytics_details(from, to)
    gs = Gattica.new({:email => 'dealkat@gmail.com', :password => "princessthecat", :profile_id => 42948679})
    results = gs.get({:start_date => from.to_s, :end_date => to.to_s,
                :dimensions => ['medium', 'source'], :metrics => ['pageviews', 'visits', 'timeOnSite'], :sort => '-pageviews'})
    @xml_data = results.to_xml
    @data = Hpricot::XML(@xml_data)
    analytics = {}
    (@data/'dxp:aggregates').each do |aggregate|
      (aggregate/'dxp:metric').each do |metric|
          analytics["pageviews"] = metric[:value] if metric[:name] == "ga:pageviews"
          analytics["visits"] = metric[:value] if metric[:name] == "ga:visits"
          analytics["timeOnSite"] = metric[:value] if metric[:name] == "ga:timeOnSite"
      end
    end
    return analytics
  end
end

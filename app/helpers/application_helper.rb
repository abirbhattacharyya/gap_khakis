# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include GoogleVisualization

  def rand_code(limit)
    str1 = ("a".."z").to_a + ("0".."9").to_a
    ary1 = []
    (1..limit).each { |i| ary1 << str1[rand(999)%str1.length] }
    return ary1.to_s
  end
end

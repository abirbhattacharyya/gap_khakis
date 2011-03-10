class Notification < ActionMailer::Base
  default_url_options[:host] = "dealkat.com"

  def forgot_password(user)
    subject    'Your forgotten password for Dealkat'
    recipients user.email
    from       sender_email

    body       :user => user
    sent_on    Time.now
#    content_type 'text/html'
  end

  def sendcoupon(recipient, payment)
    subject    'Your exclusive coupon code'
    #recipients recipient
    bcc recipient
    from       sender_email
    reply_to   "custserv@gap.com"

    body      :payment => payment
    sent_on    Time.now
    content_type 'text/html'
  end

  def dailyreport(recipient, todays_coupons, all_coupons, analytics_today, analytics_overall, today)
    subject    'daily status report'
    #recipients recipient
    bcc recipient
    from       sender_email
    reply_to   "custserv@gap.com"

    body      :todays_coupons => todays_coupons, :all_coupons => all_coupons, :analytics_today => analytics_today, :analytics_overall => analytics_overall, :today => today
    sent_on    Time.now
  end

  def sendto(recipient, product, name, message)
    subject    'Say your price with GAP'
    #recipients recipient
    bcc recipient
    from       sender_email
    reply_to   "custserv@gap.com"

    body      :product => product, :name => name, :message => message
    sent_on    Time.now
    content_type 'text/html'
  end

  protected

  def sender_email
      '"GapMyPrice" <myprice@gapmyprice.com>'
  end
end

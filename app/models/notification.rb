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
    reply_to   "dealkat@dealkat.com"

    body      :payment => payment
    sent_on    Time.now
    content_type 'text/html'
  end

  def sendto(recipient, product, name, message)
    subject    'Cool info from dealkat'
    #recipients recipient
    bcc recipient
    from       sender_email
    reply_to   "dealkat@dealkat.com"

    body      :product => product, :name => name, :message => message
    sent_on    Time.now
    content_type 'text/html'
  end

  protected

  def sender_email
      '"Dealkat" <dealkat@dealkat.com>'
  end
end

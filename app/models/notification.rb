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

  protected

  def sender_email
      '"Dealkat" <dealkat@dealkat.com>'
  end
end

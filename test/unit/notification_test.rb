require 'test_helper'

class NotificationTest < ActionMailer::TestCase
  test "forgot_password" do
    @expected.subject = 'Notification#forgot_password'
    @expected.body    = read_fixture('forgot_password')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notification.create_forgot_password(@expected.date).encoded
  end

end

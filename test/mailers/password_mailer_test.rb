require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
  test "reset" do
    mail = PasswordMailer.reset
    assert_equal "Reset", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end

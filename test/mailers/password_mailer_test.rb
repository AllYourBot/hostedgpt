require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
  setup do
    @person = people(:keith_registered)
    @user = users(:keith)

    stub_features(
      email: true,
      password_reset_email: true,
    )
    @settings = {
      email_from: "teampeople@example.com",
      product_name: "Product Name"
    }
    stub_settings(@settings)
  end

  test "reset" do
    os = "Windows"
    browser = "Chrome"

    mail = PasswordMailer.with(person: @person, os: os, browser: browser).reset

    assert_equal "Set up a new password for #{@settings[:product_name]}", mail.subject
    assert_equal [@person.email], mail.to
    assert_equal [@settings[:email_from]], mail.from
    assert_match "reset your password", mail.body.encoded
    assert_match os, mail.body.encoded
    assert_match browser, mail.body.encoded
  end
end

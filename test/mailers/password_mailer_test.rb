require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
  setup do
    @person = people(:keith_registered)
    @user = users(:keith)
    credentials(:keith_password)
  end

  test "reset" do
    os = "Windows"
    browser = "Chrome"
    product_name = "Product Name"
    from_email = "teampeople@example.com"
    setting_stub = Proc.new do |setting|
      return product_name if setting == :product_name
      return from_email if setting == :email_from
    end

    Setting.stub :method_missing, setting_stub do
      mail = PasswordMailer.with(person: @person, os: os, browser: browser).reset

      assert_equal "Set up a new password for #{product_name}", mail.subject
      assert_equal [@person.email], mail.to
      assert_equal [from_email], mail.from
      assert_match "reset your password", mail.body.encoded
      assert_match os, mail.body.encoded
      assert_match browser, mail.body.encoded
    end
  end
end

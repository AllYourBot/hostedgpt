require "test_helper"

class SendResetPasswordEmailJobTest < ActiveJob::TestCase
  setup do
    @person = people(:keith_registered)
    users(:keith)
    credentials(:keith_password)

    @os = "Windows"
    @browser = "Chrome"

    @settings = {
      email_from: "teampeople@example.com",
      product_name: "Product Name"
    }
    @features = {
      password_reset_email: true,
      email_sender_postmark: true
    }
  end

  test "calls deliver_later if person with password is found for email" do
    deliver_now_mock = Minitest::Mock.new
    deliver_now_mock.expect(:deliver_now, "delivered, yay")

    reset_mock = Minitest::Mock.new
    reset_mock.expect(:reset, deliver_now_mock)

    with_mock = Minitest::Mock.new
    with_mock.expect(:call, reset_mock, person: @person, os: @os, browser: @browser)

    PasswordMailer.stub :with, with_mock do
      SendResetPasswordEmailJob.perform_now(@person.email, @os, @browser)
    end

    assert_mock with_mock
    assert_mock reset_mock
    assert_mock deliver_now_mock
  end

  test "does not call deliver_later if person is not found for email" do
    with_mock = Minitest::Mock.new

    PasswordMailer.stub :with, with_mock do
      SendResetPasswordEmailJob.perform_now("nobodys_email@example.com", @os, @browser)
    end

    assert_mock with_mock # expecting no calls
  end

  test "does not call deliver_later if person is found for email but has no password" do
    person = people(:taylor_registered) # has no password

    with_mock = Minitest::Mock.new

    PasswordMailer.stub :with, with_mock do
      SendResetPasswordEmailJob.perform_now(person.email, @os, @browser)
    end

    assert_mock with_mock # expecting no calls
  end
end

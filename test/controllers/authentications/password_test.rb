require "test_helper"

class AuthenticationsController::PasswordTest < ActionDispatch::IntegrationTest
  test "should create session" do
    post login_path, params: {
      email: people(:keith_registered).email,
      password: "secret"
    }
    assert_redirected_to root_url # we are not actually checking that a valid session was created?
  end

  test "should ignore capitalization of email and create a session" do
    post login_path, params: {
      email: people(:keith_registered).email.capitalize,
      password: "secret"
    }
    assert_redirected_to root_url
  end

  test "should ignore whitespace around an email addresss and create a session" do
    post login_path, params: {
      email: " " + people(:keith_registered).email.capitalize,
      password: "secret"
    }
    assert_redirected_to root_url
  end

  test "should redirect back after invalid password" do
    post login_path, params: {
      email: people(:keith_registered).email,
      password: "wrong"
    }
    assert_response :see_other
    assert_match(/Invalid email or password/, flash.alert)
  end

  test "should redirect back after invalid email" do
    post login_path, params: {
      email: "wrong@email.com",
      password: "wrong"
    }
    assert_response :see_other
    assert_match(/Invalid email or password/, flash.alert)
  end
end

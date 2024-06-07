require "test_helper"

class AuthenticationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get login_path
    assert_response :success
  end

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
    assert_response :unprocessable_entity
    assert_match(/Invalid email or password/, flash.alert)
  end

  test "should redirect back after invalid email" do
    post login_path, params: {
      email: "wrong@email.com",
      password: "wrong"
    }
    assert_response :unprocessable_entity
    assert_match(/Invalid email or password/, flash.alert)
  end

  test "visiting logout should logout someone who was logged in" do
    login_as people(:keith_registered)
    get logout_path
    assert_redirected_to login_url
  end

  test "visiting logout should redirect to login if you were never logged in" do
    get logout_path
    assert_redirected_to login_url
  end

  test "visiting login when already logged in should redirect to root" do
    login_as people(:keith_registered)
    get login_path
    assert_redirected_to root_url
  end
end

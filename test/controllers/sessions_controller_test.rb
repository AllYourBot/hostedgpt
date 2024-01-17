require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get login_path
    assert_response :success
  end

  test "should create session" do
    email = people(:keith_registered).email
    password = "secret"

    post login_path, params: {email: email, password: password}
    assert_redirected_to dashboard_path
    assert_match(/Successfully logged in/, flash.notice)
  end

  test "it should redirect back with invalid password" do
    email = people(:keith_registered).email
    password = "wrong"

    post login_path, params: {email: email, password: password}
    assert_response :unprocessable_entity
    assert_match(/Invalid email or password/, flash.alert)
  end

  test "it should redirect back with invalid email" do
    email = "wrong"
    password = "secret"

    post login_path, params: {email: email, password: password}
    assert_response :unprocessable_entity
    assert_match(/Invalid email or password/, flash.alert)
  end

  test "it should strip whitespace around an email addresss" do
    email = people(:keith_registered).email
    email += " "
    password = "secret"

    post login_path, params: {email: email, password: password}
    assert_redirected_to dashboard_path
    assert_match(/Successfully logged in/, flash.notice)
  end
end

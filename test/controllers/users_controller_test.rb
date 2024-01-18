require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    post users_url, params: {email: "azbshiri@gmail.com", password: "secret"}
    assert_redirected_to dashboard_path
    assert_match "Account was successfully created", flash.notice
  end

  test "it should redirect back when the email address is already in use" do
    email = people(:keith_registered).email
    post users_url, params: {email: email, password: "secret"}
    assert_response :unprocessable_entity
    assert_match "Email has already been taken", response.body
  end

  test "it should show an error message when the password is blank" do
    email = people(:keith_registered).email
    post users_url, params: {email: email, password: ""}
    assert_response :unprocessable_entity
    assert_match "Password can&#39;t be blank", response.body
  end

  test "it should show an error message when the email is blank" do
    post users_url, params: {email: "", password: "secret"}
    assert_response :unprocessable_entity
    assert_match "Email can&#39;t be blank", response.body
  end
end

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    post users_url, params: {user: {email: "azbshiri@gmail.com", password: "password"}}.as_json
    assert_redirected_to dashboard_path
  end
end

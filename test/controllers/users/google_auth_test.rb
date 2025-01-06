require "test_helper"

class UsersController::GoogleAuthTest < ActionDispatch::IntegrationTest
  test "should NOT display a Google button when the feature is DISABLED" do
    stub_features(google_authentication: false, password_authentication: true) do
      get register_url
      assert_response :success
      assert_no_match "Sign Up with Google", response.body
    end
  end

  test "should SHOW the Google button when the feature is ENABLED" do
    stub_features(google_authentication: true, password_authentication: true) do
      get register_url
      assert_response :success
      assert_match "Sign Up with Google", response.body
    end
  end

  test "authentication - should NOT display a Google button when the feature is DISABLED" do
    stub_features(google_authentication: false, password_authentication: true) do
      get login_url
      assert_response :success
      assert_no_match "Log In with Google", response.body
    end
  end

  test "authentication - should SHOW the Google button when the feature is ENABLED" do
    stub_features(google_authentication: true, password_authentication: true) do
      get login_url
      assert_response :success
      assert_match "Log In with Google", response.body
    end
  end

  # even if password authentication is turned off, we still want to show the Microsoft button
  test "authentication - should SHOW the Google button when password authentication is DISABLED" do
    stub_features(google_authentication: true, password_authentication: false) do
      get login_url
      assert_response :success
      assert_match "Log In with Google", response.body
    end
  end
end

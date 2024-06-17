require "test_helper"

class AuthenticationsController::GoogleAuthTest < ActionDispatch::IntegrationTest
  test "should NOT display a Google button when the feature is DISABLED" do
    stub_features(google_authentication: false) do
      get login_url
      assert_response :success
      assert_no_match "Log In with Google", response.body
    end
  end

  test "should SHOW the Google button when the feature is ENABLED" do
    stub_features(google_authentication: true) do
      get login_url
      assert_response :success
      assert_match "Log In with Google", response.body
    end
  end
end

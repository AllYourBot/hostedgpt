require "test_helper"

class UsersController::GoogleAuthTest < ActionDispatch::IntegrationTest
  test "should NOT display a Google button when the feature is DISABLED" do
    stub_features(google_authentication: false) do
      get register_url
      assert_response :success
      assert_no_match "Sign Up with Google", response.body
    end
  end

  test "should SHOW the Google button when the feature is ENABLED" do
    stub_features(google_authentication: true) do
      get register_url
      assert_response :success
      assert_match "Sign Up with Google", response.body
    end
  end
end

require "test_helper"

class AuthenticationsController::MicrosoftAuthTest < ActionDispatch::IntegrationTest
  test "should NOT display a Microsoft button when the feature is DISABLED" do
    stub_features(microsoft_authentication: false) do
      get login_url
      assert_response :success
      assert_no_match "Log In with Microsoft", response.body
    end
  end

  test "should SHOW the Microsoft button when the feature is ENABLED" do
    stub_features(microsoft_authentication: true) do
      get login_url
      assert_response :success
      assert_match "Log In with Microsoft", response.body
    end
  end
end

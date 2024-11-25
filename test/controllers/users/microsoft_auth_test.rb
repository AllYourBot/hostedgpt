require "test_helper"

class UsersController::MicrosoftAuthTest < ActionDispatch::IntegrationTest
  test "should NOT display a Microsoft button when the feature is DISABLED" do
    stub_features(microsoft_graph_authentication: false) do
      get register_url
      assert_response :success
      assert_no_match "Sign Up with Microsoft", response.body
    end
  end

  test "should SHOW the Microsoft button when the feature is ENABLED" do
    stub_features(microsoft_graph_authentication: true) do
      get register_url
      assert_response :success
      assert_match "Sign Up with Microsoft", response.body
    end
  end
end

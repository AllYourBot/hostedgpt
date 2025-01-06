require "test_helper"

class UsersController::MicrosoftAuthTest < ActionDispatch::IntegrationTest
  test "register - should NOT display a Microsoft button when the feature is DISABLED" do
    stub_features(microsoft_graph_authentication: false, password_authentication: true) do
      get register_url
      assert_response :success
      assert_no_match "Sign Up with Microsoft", response.body
    end
  end

  test "register - should SHOW the Microsoft button when the feature is ENABLED" do
    stub_features(microsoft_graph_authentication: true, password_authentication: true) do
      get register_url
      assert_response :success
      assert_match "Sign Up with Microsoft", response.body
    end
  end

  test "authentication - should NOT display a Microsoft button when the feature is DISABLED" do
    stub_features(microsoft_graph_authentication: false, password_authentication: true) do
      get login_url
      assert_response :success
      assert_no_match "Log In with Microsoft", response.body
    end
  end

  test "authentication - should SHOW the Microsoft button when the feature is ENABLED" do
    stub_features(microsoft_graph_authentication: true, password_authentication: true) do
      get login_url
      assert_response :success
      assert_match "Log In with Microsoft", response.body
    end
  end

  # even if password authentication is turned off, we still want to show the Microsoft button
  test "authentication - should SHOW the Microsoft button when password authentication is DISABLED" do
    stub_features(microsoft_graph_authentication: true, password_authentication: false) do
      get login_url
      assert_response :success
      assert_match "Log In with Microsoft", response.body
    end
  end
end

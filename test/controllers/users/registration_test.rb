require "test_helper"

class UsersController::RegistrationTest < ActionDispatch::IntegrationTest
  test "should return not_found when registration is disabled" do
    stub_features(registration: false) do
      get register_url
      assert_response :not_found
    end
  end

  test "should return not_found when all auth schemes are disabled" do
    stub_features(password_authentication: false, google_authentication: false, microsoft_graph_authentication: false) do
      get register_url
      assert_response :not_found
    end
  end
end

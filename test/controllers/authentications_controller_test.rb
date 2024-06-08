require "test_helper"

class AuthenticationsControllerTest < ActionDispatch::IntegrationTest
  test "should get redirected to login page if logged out" do
    get new_assistant_message_path(assistants(:samantha))
    assert_redirected_to login_url
  end

  test "should get redirected AWAY FROM login page if already logged in" do
    login_as users(:keith)
    get login_path
    assert_response :redirect
    assert_redirected_to root_url
  end

  test "should GET TO login page if not logged in" do
    get login_path
    assert_response :success
  end

  test "visiting logout should logout someone who was logged in" do
    login_as people(:keith_registered)
    get logout_path
    assert_redirected_to login_url
  end

  test "when logged in and the authentication is deleted then the user should be logged out" do
    login_as people(:keith_registered)
    get new_assistant_message_path(assistants(:samantha))
    assert_response :success

    users(:keith).password_credential.authentications.map(&:deleted!)
    get new_assistant_message_path(assistants(:samantha))
    assert_redirected_to login_url
  end

  test "visiting logout should redirect to login if you were never logged in" do
    get logout_path
    assert_redirected_to login_url
  end

  test "visiting login when already logged in should redirect to root" do
    login_as people(:keith_registered)
    get login_path
    assert_redirected_to root_url
  end

  test "should return not_found when all auth schemes are disabled" do
    stub_features(password_authentication: false, google_authentication: false) do
      get login_path
      assert_response :not_found
    end
  end
end

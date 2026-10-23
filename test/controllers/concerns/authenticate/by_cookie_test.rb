require "test_helper"

class Authenticate::ByCookieTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:keith)
    @client = Client.find_by(token: session[:client_token])
  end

  test "should auth user with the client token saved at login" do
    get edit_settings_person_url
    assert_response :success, "A request after login should be authenticated by the client token"
  end

  test "should log out the client when its authentication IS SOFT DELETED" do
    @client.authentication.update!(deleted_at: Time.current)

    get edit_settings_person_url
    assert_redirected_to login_url, "A client whose authentication was deleted should have to log in again"
  end

  test "should keep other clients logged in when one client's authentication IS SOFT DELETED" do
    other_browser = open_session
    other_browser.post login_path, params: { email: users(:keith).email, password: "secret" }
    other_client = Client.find_by(token: other_browser.session[:client_token])
    assert other_client&.authenticated?, "The other browser should be logged in"
    assert_not_equal @client, other_client, "Each browser should log in as its own client"

    @client.authentication.update!(deleted_at: Time.current)

    other_browser.get edit_settings_person_url
    other_browser.assert_response :success, "The other browser's client should still be logged in"
  end

  test "should let the client log in again after its authentication IS SOFT DELETED" do
    @client.authentication.update!(deleted_at: Time.current)

    login_as users(:keith)
    assert @client.reload.authenticated?, "Logging in again should give the same client a new authentication"
    get edit_settings_person_url
    assert_response :success, "The client should be authenticated again"
  end
end

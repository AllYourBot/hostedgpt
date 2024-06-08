require 'test_helper'

class AuthenticateTest < ActionDispatch::IntegrationTest
  # The user-initiated login flows (e.g. password and google oauth)
  # are in test/controllers/authentications_controller_test
  # and in test/controllers/authentications/*

  setup do
    @keith = users(:keith)
    @rob = users(:rob)
  end

  test "HTTP header-based: should login user via HTTP header and redirect" do
    stub_features(http_header_authentication: true) do
      get root_url, headers: { Setting.http_header_auth_uid => @rob.auth_uid }
      assert_response :redirect
      assert_redirected_to new_assistant_message_path(@rob.assistants.ordered.first)
      # Indirect assertion of login success via redirect
    end
  end

  test "HTTP header-based: should create and login new user if registration feature enabled" do
    stub_features(http_header_authentication: true, registration: true) do
      auth_uid = "new_uid"
      email = "john.doe@hostedgpt.com"
      name = "John Doe"

      assert_difference("User.count", 1) do
        assert_difference("Person.count", 1) do
          get root_url, headers: { Setting.http_header_auth_uid => auth_uid, Setting.http_header_auth_email => email, Setting.authentication_http_header_name => name }
        end
      end

      new_user = User.find_by(auth_uid: auth_uid)
      assert new_user.present?
      assert_equal new_user.email, email

      assert_response :redirect
      assert_redirected_to new_assistant_message_path(new_user.assistants.ordered.first)
      # Indirect assertion of login success via redirect
    end
  end

  test "HTTP header-based: should render unauthorized if no HTTP header present" do
    stub_features(http_header_authentication: true) do
      get root_url
      assert_response :unauthorized
      assert_equal response.body, 'Unauthorized'
    end
  end

  test "HTTP header-based: should render unauthorized if registration feature disabled and UID not found" do
    stub_features(http_header_authentication: true, registration: false) do
      get root_url, headers: { Setting.http_header_auth_uid => 'non_existing_uid' }
      assert_response :unauthorized
      assert_equal response.body, 'Unauthorized'
    end
  end
end

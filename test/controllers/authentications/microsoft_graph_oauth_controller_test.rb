require "test_helper"

class Authentications::MicrosoftGraphOauthControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  test "cancelling a microsoft oauth flow redirects to the settings page" do
    login_as users(:keith)
    get "/auth/microsoft_graph/callback?error=access_denied&error_description=The%20user%20has%20denied%20access%20to%20the%20scope%20requested%20by%20the%20client%20application"
    assert_redirected_to edit_settings_person_path
  end

  test "cancelling a microsoft oauth flow redirects to the login" do
    get "/auth/microsoft_graph/callback?error=access_denied&error_description=The%20user%20has%20denied%20access%20to%20the%20scope%20requested%20by%20the%20client%20application"
    assert_redirected_to login_path
  end

  test "existing user can add a MicrosoftGraphCredential and redirect to edit_settings" do
    # rob has no microsoft credential
    user = users(:rob)
    login_as user
    details = details_for_email(email: user.email, first_name: "Rob", last_name: nil)
    OmniAuth.config.add_mock(:microsoft_graph, details)

    refute user.microsoft_graph_credential.present?
    assert_difference "Credential.count", 1 do
      assert_no_difference "User.count" do
        get microsoft_graph_oauth_path
      end
    end

    assert_redirected_to edit_settings_person_path
    assert_equal "Saved", flash[:notice]
    assert_credential_matches_details(user.reload.microsoft_graph_credential, details)
  end

  test "should log you in for a user that exists" do
    OmniAuth.config.add_mock(:microsoft_graph, { uid: credentials(:keith_microsoft_graph).oauth_id })
    assert_no_difference "Credential.count" do
      assert_difference "Authentication.count", 1 do
        assert_difference "Client.count", 1 do
          get microsoft_graph_oauth_path
        end
      end
    end

    assert_redirected_to root_path
    assert_logged_in(users(:keith))
  end

  test "registration is disabled" do
    OmniAuth.config.add_mock(:microsoft_graph, details_for_email(email: "john@gmail.com"))

    stub_features(microsoft_graph_authentication: true, registration: false) do
      get microsoft_graph_oauth_path
    end
    assert_redirected_to root_path
    assert_equal "Registration is disabled", flash[:alert]
  end

  test "should UPDATE A USER when authing with PASSWORD SIGNED UP USER that we find by matching email" do
    user = users(:rob)

    assert user.password_credential.present?
    refute user.microsoft_graph_credential.present?
    assert_not_equal "John", user.first_name
    assert_not_equal "Doe", user.last_name

    details = details_for_email(email: user.email)
    OmniAuth.config.add_mock(:microsoft_graph, details)

    stub_features(microsoft_graph_authentication: true, registration: true) do
      assert_no_difference "Person.count" do
        assert_no_difference "User.count" do
          assert_difference "Client.count", 1 do
            assert_difference "Credential.count", 1 do
              assert_difference "Authentication.count", 1 do
                get microsoft_graph_oauth_path
              end
            end
          end
        end
      end
    end
    user.reload

    assert_redirected_to root_path
    assert_logged_in(user)
    assert_credential_matches_details(user.microsoft_graph_credential, details)
    assert_equal details[:info][:email], user.email
    assert user.clients.ordered.last.authenticated?
  end

  test "should CREATE A USER and everything else when authing with a NOT SIGNED UP person" do
    assert people(:ali_invited).email.present?
    assert_nil people(:ali_invited).user

    details = details_for_email(email: people(:ali_invited).email)
    OmniAuth.config.add_mock(:microsoft_graph, details)

    stub_features(microsoft_graph_authentication: true, registration: true) do
      assert_no_difference "Person.count" do
        assert_difference "User.count", 1 do
          assert_difference "Client.count", 1 do
            assert_difference "Credential.count", 1 do
              assert_difference "Authentication.count", 1 do
                get microsoft_graph_oauth_path
              end
            end
          end
        end
      end
    end
    user = people(:ali_invited).reload.user
    assert user.present?

    assert_redirected_to root_path
    assert_logged_in(user)
    assert_credential_matches_details(user.microsoft_graph_credential, details)
    assert_equal details[:info][:email], user.email
    assert user.clients.ordered.last.authenticated?
  end

  test "should CREATE A USER when google authing and NOTHING EXISTS" do
    details = details_for_email(email: "john@gmail.com")
    OmniAuth.config.add_mock(:microsoft_graph, details)

    stub_features(microsoft_graph_authentication: true, registration: true) do
      assert_difference "Person.count", 1 do
        assert_difference "User.count", 1 do
          assert_difference "Client.count", 1 do
            assert_difference "Credential.count", 1 do
              assert_difference "Authentication.count", 1 do
                get microsoft_graph_oauth_path
              end
            end
          end
        end
      end
    end
    user = User.last

    assert_redirected_to root_path
    assert_logged_in(user)
    assert_credential_matches_details(user.microsoft_graph_credential, details)
    assert_equal details[:info][:email], user.email
    assert user.clients.ordered.last.authenticated?
  end

  private

  def details_for_email(email:, first_name: "John", last_name: "Doe")
    {
      uid: "new_abc123",
      info: {
        email: email,
        first_name:,
        last_name:
      },
      credentials: {
        token: "new_token",
        refresh_token: "new_refresh_token",
        scope: "openid profile email offline_access user.read mailboxsettings.read"
      }
    }
  end

  def assert_credential_matches_details(credential, details)
    user = credential.user
    assert_equal details[:info][:first_name], user.first_name if details.dig(:info, :first_name)
    assert_equal details[:info][:last_name], user.last_name if details.dig(:info, :last_name)
    assert_equal details[:uid], credential.oauth_id
    assert_equal details[:info][:email], credential.oauth_email
    assert_equal details[:credentials][:token], credential.oauth_token
    assert_equal details[:credentials][:refresh_token], credential.oauth_refresh_token
    assert_equal details[:credentials].except(:token, :refresh_token), credential.properties
  end
end

require "test_helper"

class Sessions::GoogleOauthControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  test "should add a GmailCredential and redirect to edit_settings" do
    login_as users(:keith)
    OmniAuth.config.add_mock(:gmail, { uid: users(:rob).auth_uid,
      credentials: { token: "abc123", refresh_token: "xyz789" },
      info: { email: "krschacht@hostedgpt.com" },
    })
    get "/auth/gmail/callback"
    assert_redirected_to edit_settings_person_path
    assert users(:keith).gmail_credential.present?
    assert_equal "krschacht@hostedgpt.com", users(:keith).gmail_credential.email
    assert_equal "xyz789", users(:keith).gmail_credential.refresh_token
    assert_equal "abc123", users(:keith).gmail_credential.active_authentication.token
  end

  test "should log you in for a user that exists" do
    OmniAuth.config.add_mock(:google, { uid: users(:rob).auth_uid })
    get "/auth/google/callback"
    assert_redirected_to root_path
    assert_logged_in(users(:rob))
  end

  test "should CREATE A USER when google authing with NOT SIGNED UP PERSON" do
    assert people(:ali_invited).email.present?
    assert_nil people(:ali_invited).user

    details = {
      uid: 'new_abc123',
      info: {
        email: people(:ali_invited).email,
        first_name: 'Ali',
        last_name: 'Jones'
      }
    }
    OmniAuth.config.add_mock(:google, details)
    stub_features(google_authentication: true, registration: true) do
      assert_no_difference "Person.count" do
        assert_difference "User.count", 1 do
          get "/auth/google/callback"
        end
      end
    end

    new_user = people(:ali_invited).reload.user
    assert_redirected_to root_path
    assert_logged_in(new_user)

    assert people(:ali_invited).email.present?
    assert new_user.present?

    refute new_user.password_digest.present?
    assert new_user.auth_uid.present?
    assert_equal "Ali", new_user.first_name
    assert_equal "Jones", new_user.last_name
  end

  test "should UPDATE A USER when google authing with SIGNED UP USER" do
    assert users(:keith).password_digest.present?
    refute users(:keith).auth_uid.present?
    assert_not_equal "John", users(:keith).first_name
    assert_not_equal "Doe", users(:keith).last_name

    details = {
      uid: 'new_abc123',
      info: {
        email: people(:keith_registered).email,
        first_name: 'John',
        last_name: 'Doe'
      }
    }
    OmniAuth.config.add_mock(:google, details)
    stub_features(google_authentication: true, registration: true) do
      assert_no_difference "Person.count" do
        assert_no_difference "User.count" do
          get "/auth/google/callback"
        end
      end
    end

    assert_redirected_to root_path
    assert_logged_in(users(:keith).reload)

    assert users(:keith).password_digest.present?
    assert users(:keith).auth_uid.present?
    assert_equal "John", users(:keith).first_name
    assert_equal "Doe", users(:keith).last_name
  end

  test "should CREATE A USER when google authing and NOTHING EXISTS" do
    details = {
      uid: 'new_abc123',
      info: {
        email: 'john@gmail.com',
        first_name: 'John',
        last_name: 'Doe'
      }
    }
    OmniAuth.config.add_mock(:google, details)
    stub_features(google_authentication: true, registration: true) do
      assert_difference "Person.count", 1 do
        assert_difference "User.count", 1 do
          get "/auth/google/callback"
        end
      end
    end
    new_user = User.last

    assert_redirected_to root_path
    assert_logged_in(new_user)
    assert_equal details[:info][:email], new_user.email
  end
end

require "test_helper"

class PasswordCredentialsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    people(:keith_registered)
    @user = users(:keith)
    credentials(:keith_password)

    stub_features(
      password_reset_email: true,
      email_postmark: true
    )
    stub_settings(
      email_from: "teampeople@example.com",
      product_name: "Product Name"
    )
  end

  test "should get edit" do
    token = get_test_user_token(@user)

    get edit_password_credential_url, params: { token: token }

    assert_response :success
    assert assigns(:user).is_a?(User)
    assert_equal @user, assigns(:user)
  end

  test "should redirect with invalid signature" do
    get edit_password_credential_url, params: { token: "invalid" }

    assert_response :redirect
    assert_redirected_to login_path
  end

  test "should return 404 with not_found_user" do
    token = get_test_user_token(@user)
    @user.destroy # make sure the user doesn't exist when we try to find it

    get edit_password_credential_url, params: { token: token }

    assert_response :not_found
  end

  test "should patch update" do
    token = get_test_user_token(@user)

    patch password_credential_url, params: { token: token, password: "new_password" }

    assert_response :redirect
    assert_redirected_to root_path
  end

  private

  def get_test_user_token(user)
    user.signed_id(
      purpose: Email::PasswordReset::TOKEN_PURPOSE,
      expires_in: Email::PasswordReset::TOKEN_TTL
    )
  end
end

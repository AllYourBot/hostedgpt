require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    people(:keith_registered)
    @user = users(:keith)
    credentials(:keith_password)
  end

  test "should get edit" do
    token = get_test_user_token(@user)

    get edit_password_url, params: { token: token }

    assert_response :success
    assert assigns(:user).is_a?(User)
    assert_equal @user, assigns(:user)
  end

  test "should patch update" do
    token = get_test_user_token(@user)

    patch password_url, params: { token: token, password: "new_password" }

    assert_response :redirect
    assert_redirected_to login_path
  end

  private

  def get_test_user_token(user)
    user.signed_id(
      purpose: Rails.application.config.password_reset_token_purpose,
      expires_in: Rails.application.config.password_reset_token_ttl_minutes.minutes
    )
  end
end

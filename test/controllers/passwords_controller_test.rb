require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @person = people(:keith_registered)
    users(:keith)
    credentials(:keith_password)
  end

  test "should get edit" do
    token = get_test_person_token(@person)

    get edit_password_url, params: { token: token }

    assert_response :success
    assert assigns(:person).is_a?(Person)
    assert_equal @person, assigns(:person)
  end

  test "should patch update" do
    token = get_test_person_token(@person)

    patch password_url, params: { token: token, person: { personable_attributes: { credentials_attributes: { "0" => { type: "PasswordCredential", password: "new_password" } } } } }

    assert_response :redirect
    assert_redirected_to login_path
  end

  private

  def get_test_person_token(person)
    person.signed_id(
      purpose: Rails.application.config.password_reset_token_purpose,
      expires_in: Rails.application.config.password_reset_token_ttl_minutes.minutes
    )
  end
end

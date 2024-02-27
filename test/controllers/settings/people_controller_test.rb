require "test_helper"

class Settings::PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = people(:keith_registered)
    login_as @person
  end

  test "should get edit" do
    get edit_settings_person_url
    assert_response :success
  end

  test "should update user" do
    params = person_params

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert_nil flash[:error]

    assert_equal params.slice("email"), @person.reload.slice(:email)
    assert_equal params["personable_attributes"].slice("id", "first_name", "last_name", "openai_key").values,
      @person.user.slice(:id, :first_name, :last_name, :openai_key).values
  end

  test "should fail to update when user.id is changed" do
    params = person_params
    original_user_id = params["personable_attributes"]["id"]
    params["personable_attributes"]["id"] = original_user_id + 1

    patch settings_person_url, params: { person: params }

    assert_response :unauthorized
    assert_equal original_user_id, @person.reload.user.id
  end

  test "should fail to update when user.id is nil" do
    params = person_params
    params["personable_attributes"].delete("id")

    patch settings_person_url, params: { person: params }
    assert_response :unprocessable_entity
    assert_not_nil assigns(:person).errors
  end

  private

  def person_params
    params = {}
    @person.slice(:email).each { |k,v| params[k] = "#{v}-2" }
    params["personable_attributes"] = {}
    @person.user.slice(:first_name, :last_name, :openai_key).each { |k,v| params["personable_attributes"][k] = "#{v}-2" }
    params["personable_attributes"]["id"] = @person.user.id
    params["personable_attributes"]["password"] = "secret"
    params
  end
end
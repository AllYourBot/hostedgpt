require "test_helper"

class Settings::PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = people(:keith_registered)
    @user = @person.user
    login_as @person
  end

  test "should get edit with password field VISIBLE" do
    assert @user.password_credential.present?
    get edit_settings_person_url
    assert_response :success
    assert_match "Password", response.body
  end

  test "should get edit with password field HIDDEN" do
    ensure_authed_without_password!
    assert_response :success
    assert_no_match "Password", response.body
  end

  test "should update user who DOES NOT have a password" do
    ensure_authed_without_password!
    params = person_params
    refute params["personable_attributes"]["credentials_attributes"].present?

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert_nil flash[:error]

    assert_equal params.slice("email"), @person.reload.slice(:email)
    assert_equal params["personable_attributes"].slice("id", "first_name", "last_name").values,
      @person.user.slice(:id, :first_name, :last_name).values
  end

  test "for user who has password, should update details while leaving PASSWORD UNCHANGED" do
    assert @user.password_credential.authenticate("secret")

    params = person_params
    params["personable_attributes"]["credentials_attributes"][@user.password_credential.id]["password"] = ""

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert_nil flash[:error]

    assert_equal params.slice("email"), @person.reload.slice(:email)
    assert_equal params["personable_attributes"].slice("id", "first_name", "last_name").values,
      @person.user.slice(:id, :first_name, :last_name).values
    assert @user.password_credential.reload.authenticate("secret")
  end

  test "for user who has password, should update details AND UPDATE PASSWORD" do
    assert @user.password_credential.authenticate("secret")

    params = person_params
    params["personable_attributes"]["credentials_attributes"][@user.password_credential.id]["password"] = "secret2"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert_nil flash[:error]

    assert @user.password_credential.reload.authenticate("secret2")
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
    assert_response :unprocessable_content
    assert_not_nil @controller.instance_variable_get("@person").errors
  end

  test "should gracefully ignore an attempt to alter credential type" do
    assert @user.password_credential.authenticate("secret")

    params = person_params
    params["personable_attributes"]["credentials_attributes"][@person.user.password_credential.id]["type"] = "GoogleCredential"
    patch settings_person_url, params: { person: params }
    assert_response :see_other

    assert @user.password_credential.authenticate("secret")
  end

  # Profile picture tests
  test "should upload profile picture" do
    refute @user.has_profile_picture?

    params = person_params
    params["personable_attributes"]["profile_picture"] = fixture_file_upload("test_image.jpg", "image/jpeg")

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url

    assert @user.reload.has_profile_picture?
  end

  test "should remove profile picture" do
    # First attach a profile picture
    @user.profile_picture.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    assert @user.has_profile_picture?

    params = person_params
    params["personable_attributes"]["remove_profile_picture"] = "1"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url

    refute @user.reload.has_profile_picture?
  end

  test "should handle invalid profile picture gracefully" do
    params = person_params
    params["personable_attributes"]["profile_picture"] = fixture_file_upload("test_document.txt", "text/plain")

    patch settings_person_url, params: { person: params }
    assert_response :unprocessable_entity

    refute @user.reload.has_profile_picture?
  end

  private

  def person_params
    params = {}
    @person.slice(:email).each { |k,v| params[k] = "#{v}-2" }
    params["personable_attributes"] = {}
    @person.user.slice(:first_name, :last_name).each { |k,v| params["personable_attributes"][k] = "#{v}-2" }
    params["personable_attributes"]["id"] = @person.user.id
    params["personable_attributes"]["credentials_attributes"] = {}

    # RAILSFIX: Rails form helpers handle the has_many of credentials by using a hash with the id of the hash being the object id
    # This should be fine except the rails update code with a deep has_many expects an array of hashes with an id key-value pair.
    # application_controller has a fix to patch this bug.
    params["personable_attributes"]["credentials_attributes"] = {
      @person.user.password_credential.id => @person.user.password_credential.slice(:type).merge(password: "secret")
    } if @person.user.password_credential.present?

    params
  end

  def ensure_authed_without_password!
    Client.last.authentication.update!(credential: credentials(:keith_google)) # ensure they're auth'd without password
    credentials(:keith_password).destroy
  end
end

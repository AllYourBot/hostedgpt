require "test_helper"

class Settings::PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = people(:keith_registered)
    @user = @person.user
    login_as @person
  end

  test "preferences merge preserves unrelated keys when updating dark_mode" do
    @user.preferences = { dark_mode: "light", feature: { use_ruby_llm: true } }
    @user.save!

    params = person_params
    params["personable_attributes"]["dark_mode"] = "dark"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    @user.reload

    assert_equal "dark", @user.dark_mode
    assert_equal({ use_ruby_llm: true }, @user.preferences[:feature])
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

  test "edit prunes a Gmail credential that Google reports as revoked, so it no longer shows Enabled" do
    with_feature(:google_tools, true) do
      assert @user.gmail_credential.present?

      GoogleSDK.stub :reauthenticate_credential, ->(credential) { credential.destroy; false } do
        get edit_settings_person_url
      end

      assert_response :success
      assert_nil @user.reload.gmail_credential
      assert_match I18n.t("app.settings.people.form.enable_gmail"), response.body
      assert_no_match I18n.t("app.settings.people.form.enabled"), response.body
    end
  end

  test "edit leaves a still-valid Gmail credential alone and shows Enabled" do
    with_feature(:google_tools, true) do
      GoogleSDK.stub :reauthenticate_credential, ->(credential) { true } do
        get edit_settings_person_url
      end

      assert_response :success
      assert @user.reload.gmail_credential.present?
      assert_match I18n.t("app.settings.people.form.enabled"), response.body
    end
  end

  test "edit does not call GoogleSDK when the google_tools feature is disabled" do
    with_feature(:google_tools, false) do
      GoogleSDK.stub :prune_revoked_credentials!, ->(*) { raise "should not be called" } do
        get edit_settings_person_url
      end

      assert_response :success
    end
  end

  test "updating dark_mode leaves nav_closed and feature opinions intact" do
    @user.update!(nav_closed: true)
    @user.update!(preferences: @user.preferences.merge(feature: { openai_backend: "sdk" }))

    params = person_params
    params["personable_attributes"]["dark_mode"] = "dark"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert_nil flash[:error]

    @user.reload
    assert_equal "dark", @user.dark_mode
    assert_equal true, @user.nav_closed
    assert_equal "sdk", @user.preferences[:feature][:openai_backend]
  end

  test "stores and inherits backend choices without touching other preferences" do
    @user.update!(dark_mode: "dark", nav_closed: true)

    params = person_params
    params["backend_choices"] = { "openai_ai_backend" => "ruby_llm", "gemini_ai_backend" => "", "openrouter_ai_backend" => "sdk" }

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert_nil flash[:error]

    @user.reload
    assert_equal "ruby_llm", @user.features[:openai_ai_backend]
    assert_nil @user.features[:gemini_ai_backend]
    assert_equal "sdk", @user.features[:openrouter_ai_backend]
    assert_equal true, @user.nav_closed
    assert_equal "dark", @user.dark_mode
  end

  test "the settings form renders an OpenRouter backend choice row" do
    get edit_settings_person_url
    assert_response :success
    assert_select "span", text: "OpenRouter"
    assert_select "input[type=radio][name='person[backend_choices][openrouter_ai_backend]'][value='sdk']"
    assert_select "input[type=radio][name='person[backend_choices][openrouter_ai_backend]'][value='ruby_llm'][disabled]"
  end

  private

  def with_feature(name, enabled)
    original = Feature.features_hash
    Feature.features_hash = Feature.features.merge(name.to_sym => enabled)
    yield
  ensure
    Feature.features_hash = original
  end

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

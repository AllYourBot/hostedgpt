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

  test "after a failed update the language links go back to the edit page WITHOUT the submitted form" do
    params = person_params
    params["personable_attributes"].delete("id")

    patch settings_person_url, params: { person: params, authenticity_token: "secret-token" },
      headers: { "Referer" => edit_settings_person_url(locale: :de) }
    assert_response :unprocessable_content

    assert_select "a[href='#{edit_settings_person_path}?locale=en']", { count: 1 }, "The EN link should point back to the edit page"
    assert_select "a[href='#{edit_settings_person_path}?locale=de']", { count: 1 }, "The DE link should point back to the edit page"
    assert_select "a[href*='authenticity_token']", { count: 0 }, "No link should carry the CSRF token"
    assert_select "a[href*='person%5B']", { count: 0 }, "No link should carry the submitted form"
  end

  test "after a failed update WITHOUT a referer the language links go to the root" do
    params = person_params
    params["personable_attributes"].delete("id")

    patch settings_person_url, params: { person: params }
    assert_response :unprocessable_content

    assert_select "a[href='#{root_path}?locale=de']", { count: 1 }, "The DE link should fall back to the root"
  end

  test "on edit the language links keep the page's query string" do
    get edit_settings_person_url(tab: "profile")

    assert_select "a[href='#{edit_settings_person_path}?locale=de&tab=profile']", { count: 1 }, "The DE link should keep the tab param"
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

  test "edit shows a Disconnect button for each CONNECTED Google tool" do
    with_feature(:google_tools, true) do
      GoogleSDK.stub :reauthenticate_credential, ->(credential) { true } do
        get edit_settings_person_url
      end

      assert_response :success
      { gmail: :keith_gmail, google_tasks: :keith_google_tasks, google_calendar: :keith_google_calendar }.each do |tool, fixture|
        assert_select "label[for=person_disconnect_#{tool}]", { text: "Disconnect" }, "#{tool} should offer Disconnect"
        assert_select "form[action='#{settings_google_app_credential_path(credentials(fixture))}'] input[name=_method][value=delete]", 1,
          "#{tool} should have a delete form for its credential"
        assert_select "button#person_disconnect_#{tool}[data-turbo-confirm]", 1, "#{tool} should confirm before disconnecting"
      end
    end
  end

  test "edit shows Enable INSTEAD OF Disconnect for a Google tool that is NOT connected" do
    credentials(:keith_gmail).destroy!

    with_feature(:google_tools, true) do
      GoogleSDK.stub :reauthenticate_credential, ->(credential) { true } do
        get edit_settings_person_url
      end

      assert_response :success
      assert_select "label[for=person_authorize_gmail]", { text: I18n.t("app.settings.people.form.enable_gmail") }, "Gmail should offer Enable"
      assert_select "label[for=person_disconnect_gmail]", false, "Gmail should not offer Disconnect"
      assert_select "button#person_disconnect_gmail", false, "Gmail should have no disconnect form"
      assert_select "label[for=person_disconnect_google_tasks]", 1, "Google Tasks should still offer Disconnect"
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

  test "turning off show_thinking keeps the other preferences" do
    @user.update!(dark_mode: "dark", nav_closed: true)

    params = person_params
    params["personable_attributes"]["show_thinking"] = "0"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url

    @user.reload
    refute @user.show_thinking?
    assert_equal "dark", @user.dark_mode
    assert_equal true, @user.nav_closed
  end

  test "the settings form shows the show_thinking checkbox checked by default" do
    get edit_settings_person_url
    assert_select "input[type=checkbox][name='person[personable_attributes][show_thinking]'][checked]"
  end

  test "turning off ask_follow_ups keeps the other preferences" do
    @user.update!(dark_mode: "dark", show_thinking: false)

    params = person_params
    params["personable_attributes"]["ask_follow_ups"] = "0"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url

    @user.reload
    refute @user.ask_follow_ups?, "Follow-ups should be turned off"
    assert_equal "dark", @user.dark_mode, "dark_mode should not have changed"
    refute @user.show_thinking?, "show_thinking should not have changed"
  end

  test "the settings form shows the ask_follow_ups checkbox checked by default" do
    get edit_settings_person_url
    assert_select "input[type=checkbox][name='person[personable_attributes][ask_follow_ups]'][checked]"
  end

  test "the settings form shows the ask_follow_ups checkbox UNCHECKED once the user turned follow-ups off" do
    @user.update!(ask_follow_ups: false)

    get edit_settings_person_url
    assert_select "input[type=checkbox][name='person[personable_attributes][ask_follow_ups]']:not([checked])"
  end

  test "turning on provider_web_search keeps the other preferences" do
    @user.update!(dark_mode: "dark", ask_follow_ups: false)

    params = person_params
    params["personable_attributes"]["provider_web_search"] = "1"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url

    @user.reload
    assert @user.provider_web_search?, "Provider web search should be turned on"
    assert_equal "dark", @user.dark_mode, "dark_mode should not have changed"
    refute @user.ask_follow_ups?, "ask_follow_ups should not have changed"
  end

  test "the settings form shows the provider_web_search checkbox unchecked by default" do
    get edit_settings_person_url
    assert_select "input[type=checkbox][name='person[personable_attributes][provider_web_search]']:not([checked])"
  end

  test "the settings form shows the use_ip_location checkbox UNCHECKED by default" do
    get edit_settings_person_url
    assert_select "input[type=checkbox][name='person[personable_attributes][use_ip_location]']:not([checked])"
  end

  test "turning on use_ip_location saves it" do
    params = person_params
    params["personable_attributes"]["use_ip_location"] = "1"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert @user.reload.use_ip_location?, "Using the IP location should be turned on"
  end

  test "setting ui_scale saves it and sizes every page with it" do
    @user.update!(dark_mode: "dark")

    params = person_params
    params["personable_attributes"]["ui_scale"] = "120"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url

    @user.reload
    assert_equal 120, @user.ui_scale, "The interface size should be saved"
    assert_equal "dark", @user.dark_mode, "dark_mode should not have changed"

    get edit_settings_person_url
    assert_select "html[style='--ui-scale: 1.2']", true, "The page should be rendered at the saved size"
    assert_select "body[data-ui-scale-percent-value='120']", true, "The body should re-apply the saved size on Turbo visits"
    assert_select "input[type=range][name='person[personable_attributes][ui_scale]'][value='120']"
    assert_select "[data-ui-scale-target=label]", "120%"
  end

  test "the settings form shows the ui_scale slider at 100% by default" do
    get edit_settings_person_url
    assert_select "html[style='--ui-scale: 1.0']", true, "The page should be rendered at the default size"
    assert_select "input[type=range][name='person[personable_attributes][ui_scale]'][value='100'][min='70'][max='170'][step='5']"
    assert_select "[data-ui-scale-target=label]", "100%"
  end

  test "setting ui_scale OUTSIDE the slider's range saves the nearest size" do
    params = person_params
    params["personable_attributes"]["ui_scale"] = "500"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert_equal 170, @user.reload.ui_scale, "The interface size should stop at the largest size"
  end

  test "updating dark_mode leaves nav_closed and feature opinions intact" do
    @user.update!(nav_closed: true)
    @user.update!(feature: { "some_custom_feature" => "sdk" })

    params = person_params
    params["personable_attributes"]["dark_mode"] = "dark"

    patch settings_person_url, params: { person: params }
    assert_redirected_to edit_settings_person_url
    assert_nil flash[:error]

    @user.reload
    assert_equal "dark", @user.dark_mode
    assert_equal true, @user.nav_closed
    assert_equal "sdk", @user.feature["some_custom_feature"]
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

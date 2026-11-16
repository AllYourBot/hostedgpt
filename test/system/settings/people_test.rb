require "application_system_test_case"

class Settings::PeopleTest < ApplicationSystemTestCase
  setup do
    @person = people(:keith_registered)
    login_as @person
    visit edit_settings_person_url
  end

  test "should update Person" do
    attr = {
      email: @person.email+"-2",
      first_name: @person.user.first_name+"-2",
      last_name: @person.user.last_name+"-2",
    }

    assert_not_equal attr[:email], @person.reload.email
    assert_not_equal attr.except(:email), @person.user.slice(:first_name, :last_name).symbolize_keys

    fill_in "Email", with: attr[:email]
    fill_in "First name", with: attr[:first_name]
    fill_in "Last name", with: attr[:last_name]
    fill_in "Password", with: "secret"

    click_text "Save"

    assert_alert "Saved"
    assert_current_path edit_settings_person_url

    assert_equal attr[:email], @person.reload.email
    assert_equal attr.except(:email), @person.user.slice(:first_name, :last_name).symbolize_keys
  end

  test "should update Person without setting the password" do
    attr = {
      email: @person.email+"-2",
      first_name: @person.user.first_name+"-2",
      last_name: @person.user.last_name+"-2",
    }

    assert_not_equal attr[:email], @person.reload.email
    assert_not_equal attr.except(:email), @person.user.slice(:first_name, :last_name).symbolize_keys

    fill_in "Email", with: attr[:email]
    fill_in "First name", with: attr[:first_name]
    fill_in "Last name", with: attr[:last_name]

    click_text "Save"

    assert_alert "Saved"
    assert_current_path edit_settings_person_url

    assert_equal attr[:email], @person.reload.email
    assert_equal attr.except(:email), @person.user.slice(:first_name, :last_name).symbolize_keys
  end

  test "should disconnect Gmail and offer to enable it again" do
    stub_features(google_tools: true) do
      GoogleSDK.stub :reauthenticate_credential, ->(credential) { true } do
        visit edit_settings_person_url
        assert_selector "label[for=person_disconnect_gmail]"

        accept_confirm { find("label[for=person_disconnect_gmail]").click }

        assert_alert "Disconnected"
        assert_current_path edit_settings_person_url
        assert_text "Enable Gmail"
        assert_no_selector "label[for=person_disconnect_gmail]"
        assert_selector "label[for=person_disconnect_google_tasks]"
      end
    end

    assert_nil @person.user.reload.gmail_credential, "Gmail should no longer be connected"
    assert @person.user.google_tasks_credential.present?, "Google Tasks should still be connected"
  end

  test "the settings sidebar links to the assistants page instead of listing each assistant" do
    within("section#menu") { click_text "Assistants" }
    assert_current_path settings_assistants_path
    assert_no_selector "section#menu picture"
  end

end

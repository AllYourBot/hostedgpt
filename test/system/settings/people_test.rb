require "application_system_test_case"

class Settings::PeopleTest < ApplicationSystemTestCase
  setup do
    @person = people(:keith_registered)
    login_as @person
  end

  test "should update Person" do
    visit edit_settings_person_url

    attr = {
      email: @person.email+"-2",
      first_name: @person.user.first_name+"-2",
      last_name: @person.user.last_name+"-2",
      openai_key: @person.user.openai_key+"-2",
    }

    assert_not_equal attr[:email], @person.reload.email
    assert_not_equal attr.except(:email), @person.user.slice(:first_name, :last_name, :openai_key).symbolize_keys

    fill_in "Email", with: attr[:email]
    fill_in "First name", with: attr[:first_name]
    fill_in "Last name", with: attr[:last_name]
    fill_in "Password", with: "secret"
    fill_in "Openai key", with: attr[:openai_key]

    click_on "Save"

    assert_text "Person was successfully updated"
    assert_current_path edit_settings_person_url

    assert_equal attr[:email], @person.reload.email
    assert_equal attr.except(:email), @person.user.slice(:first_name, :last_name, :openai_key).symbolize_keys
  end
end

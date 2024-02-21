require "application_system_test_case"

class Settings::PeopleTest < ApplicationSystemTestCase
  setup do
    @person = people(:keith_registered)
    login_as @person
  end

  test "should update Person" do
    visit edit_settings_person_url

    fill_in "Email", with: @person.email+"-2"
    fill_in "First name", with: @person.user.first_name+"-2"
    fill_in "Last name", with: @person.user.last_name+"-2"
    fill_in "Password", with: "secret"
    fill_in "Openai key", with: @person.user.openai_key+"-2"

    click_on "Update Person"

    assert_text "Person was successfully updated"
    assert_current_path edit_settings_person_url
  end

  test "should error if Person.user.id is blank" do
    visit edit_settings_person_url

    fill_in "Password", with: "secret"
    fill_in "Id", with: ""

    click_on "Update Person"

    assert_text "errors prohibited"
  end
end

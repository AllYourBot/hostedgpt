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
      openai_key: @person.user.openai_key+"-2",
      anthropic_key: @person.user.anthropic_key+"-2",
    }

    assert_not_equal attr[:email], @person.reload.email
    assert_not_equal attr.except(:email), @person.user.slice(:first_name, :last_name, :openai_key).symbolize_keys

    fill_in "Email", with: attr[:email]
    fill_in "First name", with: attr[:first_name]
    fill_in "Last name", with: attr[:last_name]
    fill_in "Password", with: "secret"
    fill_in "OpenAI Key", with: attr[:openai_key]
    fill_in "Anthropic Key", with: attr[:anthropic_key]

    click_text "Save"

    assert_toast "Saved"
    assert_current_path edit_settings_person_url

    assert_equal attr[:email], @person.reload.email
    assert_equal attr.except(:email), @person.user.slice(:first_name, :last_name, :openai_key, :anthropic_key).symbolize_keys
  end

  test "clicking How? on OpenAI reveals instructions" do
    assert_hidden "#openai-instructions"
    click_element "#how-openai"

    assert_visible "#openai-instructions"
    assert_hidden "#how-openai"
  end

  test "clicking How? on Anthropic reveals instructions" do
    assert_hidden "#anthropic-instructions"
    click_element "#how-anthropic"

    assert_visible "#anthropic-instructions"
    assert_hidden "#how-anthropic"
  end
end

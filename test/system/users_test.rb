require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    visit root_url
  end

  test "the new user form reveals more fields when password is focused and those fields stay" do
    click_text "Sign up", match: :first

    assert_visible "#person_email", wait: 0.2
    assert_visible "#person_personable_attributes_password"

    assert_hidden "#person_personable_attributes_first_name"
    assert_hidden "#person_personable_attributes_last_name"
    assert_hidden "#person_personable_attributes_openai_key"

    fill_in "Email", with: "email@email.com"
    fill_in "Password", with: "secret"

    sleep 0.1

    assert_visible "#person_personable_attributes_first_name"
    assert_visible "#person_personable_attributes_last_name"
    assert_visible "#person_personable_attributes_openai_key"

    fill_in "Email", with: "changed@email.com"
    fill_in "Password", with: "secret" # this triggers a second focus event

    sleep 0.1

    assert_visible "#person_personable_attributes_first_name"
    assert_visible "#person_personable_attributes_last_name"
    assert_visible "#person_personable_attributes_openai_key"
  end

  test "should display errors if fields are left blank" do
    click_text "Sign up", match: :first
    fill_in "Email", with: "tester@test.com"
    click_text "Sign Up"

    assert_text "can't be blank"
  end

  test "should create a new user" do
    click_text "Sign up", match: :first

    fill_in "Email", with: "tester@test.com"
    fill_in "Password", with: "secret"
    fill_in "First name", with: "John"
    fill_in "Last name", with: "Doe"
    fill_in "OpenAI Key", with: "abc123"

    click_text "Sign Up"

    sleep 0.3
    assert_current_path new_assistant_message_path(Person.ordered.last.user.assistants.ordered.first)
  end

  test "should login as an existing user" do
    fill_in "Email address", with: @user.person.email
    fill_in "Password", with: "secret"
    click_text "Log In"

    sleep 0.3
    assert_current_path new_assistant_message_path(@user.assistants.ordered.first)
  end
end

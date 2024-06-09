require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase

  setup do
    @user = users(:keith)
    visit root_url
  end

  test "the new user form reveals more fields when password is focused and those fields stay" do
    click_text "Sign up", match: :first

    assert_text "Email"
    assert_text "Password"
    refute_text "Full Name"

    fill_in "Email", with: "email@email.com"
    fill_in "Password", with: "secret"

    sleep 0.1

    assert_text "Full Name"

    fill_in "Email", with: "changed@email.com"
    fill_in "Password", with: "secret" # this triggers a second focus event

    sleep 0.1

    assert_visible "#person_personable_attributes_name"
  end

  test "should create a new user" do
    click_text "Sign up", match: :first

    fill_in "Email", with: "tester@test.com"
    fill_in "Password", with: "secret"
    fill_in "Name", with: "John Doe"

    click_text "Sign Up"

    sleep 0.3
    user = Person.ordered.last.user
    assert_current_path new_assistant_message_path(user.assistants.ordered.first)

    assert_equal "tester@test.com", user.person.email
    assert_equal "John Doe", user.name
    assert_equal 1, user.credentials.count
    assert user.password_credential.password_digest.present?
  end
end

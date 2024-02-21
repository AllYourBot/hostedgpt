require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    visit root_url
  end

  test "should create a new user" do
    click_text "Sign up", match: :first

    fill_in "Email address", with: "tester@test.com"
    fill_in "Password", with: "secret"
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

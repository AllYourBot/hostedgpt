require "application_system_test_case"

class Authentications::PasswordTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    visit root_url
  end

  test "should login as an existing user and logout" do
    assert_active "#email"

    fill_in "Email address", with: @user.person.email
    fill_in "Password", with: "secret"
    click_text "Log In"

    assert_current_path new_assistant_message_path(@user.assistants.ordered.first)

    visit logout_path
    assert_current_path login_path
  end

  test "when password is wrong, it shows an error message and keeps email pre-filled" do
    previous_path = current_path
    fill_in "Email address", with: @user.person.email
    fill_in "Password", with: "wrong"
    click_text "Log In"

    sleep 0.1
    assert_text "Invalid email or password"
    assert_equal @user.person.email, find("#email").value
    assert_active "#password"
    assert_current_path previous_path
  end
end

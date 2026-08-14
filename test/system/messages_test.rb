require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
  end

  test "after logging in, the user is redirected to the root path when assistants page is enabled" do
    with_assistants_page(true) do
      visit root_url

      fill_in "Email address", with: @user.email
      fill_in "Password", with: "secret"
      click_text "Log In"

      assert_current_path root_path
    end
  end

  test "after logging in, the user is redirected to the assistant page when assistants page is disabled" do
    with_assistants_page(false) do
      visit root_url

      fill_in "Email address", with: @user.email
      fill_in "Password", with: "secret"
      click_text "Log In"

      assistant = @user.assistants.ordered.first
      assert_current_path new_assistant_message_path(assistant)
    end
  end

  test "visiting the index defaults to the first assistant and starts a new conversation when assistants page is disabled" do
    with_assistants_page(false) do
      assistant = @user.assistants.ordered.first
      login_as @user
      visit root_url

      assert_current_path new_assistant_message_path(assistant)
      assert_selector "#assistants .relationship", text: assistant.name
    end
  end

  test "visiting the index stays on the root path when assistants page is enabled" do
    with_assistants_page(true) do
      assistant = @user.assistants.ordered.first
      login_as @user
      visit root_url

      assert_current_path root_path
    end
  end
end

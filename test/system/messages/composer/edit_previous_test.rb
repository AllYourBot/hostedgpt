require "application_system_test_case"

class MessagesComposerEditPreviousTest < ApplicationSystemTestCase
  include NavigationHelper

  setup do
    login_as users(:keith)
    @conversation = conversations(:greeting)
    visit_and_scroll_wait conversation_messages_path(@conversation)
  end

  test "pressing up while focused in composer edits the previous message" do
    assert_active composer_selector

    refute_text "Cancel"
    send_keys "up"
    assert_text "Cancel"

    assert last_user_message.find_role("cancel")
  end

  test "pressing up once text has been entered into the composer does not edit the previous message" do
    assert_active composer_selector
    send_keys "Starting to type a question..."

    refute_text "Cancel"
    send_keys "up"
    refute_text "Cancel"
  end
end

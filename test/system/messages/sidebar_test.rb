require "application_system_test_case"

class MessagesSidebarTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
  end

  test "clicking conversations in the left side updates the right column, the path, and back button works as expected" do
    assistant = @user.assistants.sorted.first

    visit root_url

    assert_current_path new_assistant_message_path(assistant)
    assert_selected_assistant assistant

    click_on conversations(:greeting).title
    assert_current_path conversation_messages_path(conversations(:greeting))
    assert_selected_assistant conversations(:greeting).assistant
    assert_first_message conversations(:greeting).messages.sorted.first

    click_on conversations(:javascript).title
    assert_current_path conversation_messages_path(conversations(:javascript))
    assert_selected_assistant conversations(:javascript).assistant
    assert_first_message conversations(:javascript).messages.sorted.first

    click_on conversations(:ruby_version).title
    assert_current_path conversation_messages_path(conversations(:ruby_version))
    assert_selected_assistant conversations(:ruby_version).assistant
    assert_first_message conversations(:ruby_version).messages.sorted.first

    page.go_back
    assert_current_path conversation_messages_path(conversations(:javascript))
    assert_selected_assistant conversations(:javascript).assistant
    assert_first_message conversations(:javascript).messages.sorted.first

    page.go_back
    assert_current_path conversation_messages_path(conversations(:greeting))
    assert_selected_assistant conversations(:greeting).assistant
    assert_first_message conversations(:greeting).messages.sorted.first

    page.go_back
    assert_current_path new_assistant_message_path(assistant)
    assert_selected_assistant assistant
  end

  test "sidebar close handle shows proper tooltip and hides/shows column when clicked" do
    assert_visible "#left-column"

    assert_visible "#left-handle"
    assert_shows_tooltip "#left-handle", "Close sidebar"
    assert_hidden "#right-handle"

    find("#handle").click

    assert_hidden "#left-column"

    assert_visible "#right-handle"
    assert_shows_tooltip "#right-handle", "Open sidebar"
    assert_hidden "#left-handle"

    find("#handle").click

    assert_visible "#left-column"

    assert_visible "#left-handle"
    assert_shows_tooltip "#left-handle", "Close sidebar"
    assert_hidden "#right-handle"
  end

  test "meta+. opens and closes sidebar" do
    assert_visible "#left-column"

    assert_visible "#left-handle"
    assert_hidden "#right-handle"

    send_keys "meta+."

    assert_hidden "#left-column"

    assert_visible "#right-handle"
    assert_hidden "#left-handle"

    send_keys "meta+."

    assert_visible "#left-column"

    assert_visible "#left-handle"
    assert_hidden "#right-handle"
  end

  test "meta+shift+s opens and closes sidebar" do
    assert_visible "#left-column"

    assert_visible "#left-handle"
    assert_hidden "#right-handle"

    send_keys "meta+shift+s"

    assert_hidden "#left-column"

    assert_visible "#right-handle"
    assert_hidden "#left-handle"

    send_keys "meta+shift+s"

    assert_visible "#left-column"

    assert_visible "#left-handle"
    assert_hidden "#right-handle"
  end

  test "clicking the assistant name in the sidebar starts a new conversation" do
    conversation_path = conversation_messages_path(conversations(:greeting))
    visit conversation_path
    assert_current_path conversation_path

    assistant1 = @user.assistants.sorted.first
    click_on assistant1.name, match: :first
    assert_current_path new_assistant_message_path(assistant1)

    assistant2 = @user.assistants.sorted.second
    second_assistant_container = all("#assistants .assistant", visible: :false)[1]
    second_assistant_container.hover
    pencil_on_second_assistant = all("#assistants a.assistant-pencil", visible: :false)[1]
    pencil_on_second_assistant.click
    assert_current_path new_assistant_message_path(assistant2)
  end


  private

  def assert_selected_assistant(assistant)
    assert_selector "#assistants .relationship", text: assistant.name
  end

  def assert_first_message(message)
    assert_selector "#messages > :first-child .content_text", text: message.content_text
  end
end

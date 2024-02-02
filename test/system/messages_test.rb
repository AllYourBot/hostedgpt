require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  setup do
    @message = messages(:hear_me)
    @user = @message.conversation.user
    login_as @user
  end

  test "after logging in, the user is redirected to the right path" do
    assistant = @user.assistants.order(:id).first
    assert_current_path new_assistant_message_path(assistant)
  end

  test "visiting the index defaults to GPT-4 and starts a new conversation" do
    assistant = @user.assistants.order(:id).first

    visit root_url

    assert_current_path new_assistant_message_path(assistant)
    assert_selector "#assistants .relationship", text: "GPT-4"
  end

  test "clicking conversations in the left side updates the right column, the path, and back button works as expected" do
    assistant = @user.assistants.order(:id).first

    visit root_url

    assert_current_path new_assistant_message_path(assistant)
    assert_selected_assistant assistant

    click_on conversations(:greeting).title
    assert_current_path conversation_messages_path conversations(:greeting)
    assert_selected_assistant conversations(:greeting).assistant
    assert_first_message conversations(:greeting).messages.order(:created_at).first

    click_on conversations(:javascript).title
    assert_current_path conversation_messages_path conversations(:javascript)
    assert_selected_assistant conversations(:javascript).assistant
    assert_first_message conversations(:javascript).messages.order(:created_at).first

    click_on conversations(:ruby_version).title
    assert_current_path conversation_messages_path conversations(:ruby_version)
    assert_selected_assistant conversations(:ruby_version).assistant
    assert_first_message conversations(:ruby_version).messages.order(:created_at).first

    page.go_back
    assert_current_path conversation_messages_path conversations(:javascript)
    assert_selected_assistant conversations(:javascript).assistant
    assert_first_message conversations(:javascript).messages.order(:created_at).first

    page.go_back
    assert_current_path conversation_messages_path conversations(:greeting)
    assert_selected_assistant conversations(:greeting).assistant
    assert_first_message conversations(:greeting).messages.order(:created_at).first

    page.go_back
    assert_current_path new_assistant_message_path(assistant)
    assert_selected_assistant assistant
  end

  test "sidebar handle shows proper tooltip and hides/shows column when clicked" do
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


  private

  def assert_selected_assistant(assistant)
    assert_selector "#assistants .relationship", text: assistant.name
  end

  def assert_first_message(message)
    assert_selector "#messages > :first-child .content_text", text: message.content_text
  end

  def assert_visible(selector)
    element = page.find(selector, visible: false) rescue nil
    assert element, "Expected to find visible css #{selector}, but the element was not found."
    assert element.visible?, "Expected to find visible css #{selector}. It was found but it is hidden."
  end

  def assert_hidden(selector)
    element = page.find(selector, visible: false) rescue nil
    assert element, "Expected to find hidden css #{selector}, but the element was not found."
    refute element.visible?, "Expected to find hidden css #{selector}. It was found but it is visible."
  end

  def assert_shows_tooltip(selector, text)
    assert_selector selector, class: "tooltip"
    assert_equal text, page.find(selector)[:'data-tip']
  end
end

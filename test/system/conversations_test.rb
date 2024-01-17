require "application_system_test_case"

class ConversationsTest < ApplicationSystemTestCase
  setup do
    @conversation = conversations(:greeting)
    login_as @conversation.user
  end

  test "visiting the index" do
    visit conversations_url
    assert_selector "h1", text: "Conversations"
  end

  test "should create conversation" do
    visit conversations_url
    click_on "New conversation"

    fill_in "Assistant", with: @conversation.assistant_id
    fill_in "Title", with: @conversation.title
    click_on "Create Conversation"

    assert_text "Conversation was successfully created"
  end

  test "when a message arrives while viewing the conversation, it is displayed" do
    visit conversation_url(@conversation)
    message_text = "Hello! #{Time.now}"
    @conversation.messages.create! content_text: message_text, role: :user
    assert_text message_text
  end
end

require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @message = messages(:hear_me)
    @conversation = @message.conversation
  end

  test "should get index" do
    get conversation_messages_url(@conversation)
    assert_response :success
  end

  test "should get new" do
    get new_conversation_message_url(@conversation)
    assert_response :success
  end

  test "should create message" do
    assert_difference("Message.count") do
      post conversation_messages_url(@conversation), params: { message: { role: @message.role, content_text: @message.content_text } }
    end

    assert_redirected_to message_url(Message.last)
    assert_equal @conversation.id, Message.last.conversation_id
  end

  test "should show message" do
    get message_url(@message)
    assert_response :success
  end

  test "should get edit" do
    get edit_message_url(@message)
    assert_response :success
  end

  test "should update message" do
    patch message_url(@message), params: { message: { role: @message.role, content_text: @message.content_text } }
    assert_redirected_to message_url(@message)
  end

  test "should destroy message" do
    assert_difference("Message.count", -1) do
      delete message_url(@message)
    end

    assert_redirected_to conversation_messages_url(@conversation)
  end
end

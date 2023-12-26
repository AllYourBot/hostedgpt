require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @message = messages(:hear_me)
  end

  test "should get index" do
    get messages_url
    assert_response :success
  end

  test "should get new" do
    get new_message_url
    assert_response :success
  end

  test "should create message" do
    assert_difference("Message.count") do
      post messages_url, params: {message: {conversation_id: @message.conversation_id, role: @message.role, content_text: @message.content_text}}
    end

    assert_redirected_to message_url(Message.last)
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
    patch message_url(@message), params: {message: {conversation_id: @message.conversation_id, role: @message.role, run_id: @message.run_id, content_text: @message.content_text}}
    assert_redirected_to message_url(@message)
  end

  test "should destroy message" do
    assert_difference("Message.count", -1) do
      delete message_url(@message)
    end

    assert_redirected_to messages_url
  end
end

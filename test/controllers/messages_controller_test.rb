require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @message = messages(:hear_me)
    @conversation = @message.conversation
    @user = @conversation.user
    @assistant = @conversation.assistant
    login_as @user
  end

  test "should get index" do
    get conversation_messages_url(@conversation)
    assert_response :success
  end

  test "should get new" do
    get new_assistant_message_url(@assistant)
    assert_response :success
  end

  test "should create message when conversation_id is provided" do
    assert_difference "Message.count", 2 do
      post assistant_messages_url(@assistant), params: { message: { conversation_id: @message.conversation_id, content_text: @message.content_text } }
    end

    assert_redirected_to conversation_messages_url(@conversation)
    assert_equal @conversation.id, Message.last.conversation_id
  end

  test "should create message AND create conversation when conversation_id is nil" do
    assert_difference "Message.count", 2 do
      assert_difference "Conversation.count", 1 do
        post assistant_messages_url(@assistant), params: { message: { content_text: @message.content_text } }
      end
    end

    conversation = Message.last.conversation
    assert_instance_of Conversation, conversation
    assert_redirected_to conversation_messages_url(conversation)
    assert_equal @assistant, conversation.assistant
    assert_equal @user, conversation.user
  end

  test "should fail to create message when there is no content_text" do
    post assistant_messages_url(@assistant), params: { message: { content_text: nil } }
    assert_response :unprocessable_entity
  end

  test "should fail to create message when there are no params" do
    post assistant_messages_url(@assistant)
    assert_response :bad_request
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

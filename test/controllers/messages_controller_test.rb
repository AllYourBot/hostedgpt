require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @message = messages(:hear_me)
    @conversation = @message.conversation
    @user = @conversation.user
    @assistant = @conversation.assistant
    login_as @user
  end

  test "index REDIRECTS if no version is provided" do
    get conversation_messages_url(@conversation)
    assert_redirected_to conversation_messages_url(@conversation, version: 1)
    follow_redirect!
    assert_response :success
  end

  test "index DOES NOT REDIRECT if version is provided" do
    get conversation_messages_url(@conversation, version: 1)
    assert_response :success
  end

  test "should get new" do
    get new_assistant_message_url(@assistant)
    assert_response :success
  end

  test "should show message" do
    get message_url(@message)
    assert_response :success
  end

  test "should get edit" do
    get edit_message_url(@message)
    assert_response :success
  end

  test "should create message when conversation_id is provided" do
    assert_difference "Message.count", 2 do
      post assistant_messages_url(@assistant), params: { message: { conversation_id: @message.conversation_id, content_text: @message.content_text } }
    end

    assert_redirected_to conversation_messages_url(@conversation, version: 1)
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
    assert_redirected_to conversation_messages_url(conversation, version: 1)
    assert_equal @assistant, conversation.assistant
    assert_equal @user, conversation.user
  end

  test "after creating message it redirects to the version of the message" do
    post assistant_messages_url(@assistant), params: { message: {
      conversation_id: @message.conversation_id,
      content_text: @message.content_text,
      index: 1,
      version: 2,
      branched: true,
      branched_from_version: 1,
    }}

    message = Message.last
    assert_equal 2, message.version
    assert_redirected_to conversation_messages_url(@conversation, version: 2)
  end

  test "should fail to create message when there is no content_text" do
    post assistant_messages_url(@assistant), params: { message: { content_text: nil } }
    assert_response :unprocessable_entity
  end

  test "should fail to create message when there are no params" do
    post assistant_messages_url(@assistant)
    assert_response :bad_request
  end

  test "should fail to create a message when index and version are an invalid combination" do
    post assistant_messages_url(@assistant), params: { message: {
      conversation_id: @message.conversation_id,
      content_text: @message.content_text,
      index: 1,
      version: 10,
    }}
    assert_response :unprocessable_entity
  end

  test "update succeeds and redirect to message's EXISTING VERSION" do
    message = messages(:message2_v1)

    patch message_url(message), params: { message: { id: message.id, content_text: "new message" } }
    assert_redirected_to conversation_messages_url(message.conversation, version: 1)
  end

  test "update succeeds and redirect to DIFFERENT VERSION when update has a new version in the URL" do
    message = messages(:message2_v1)

    patch message_url(message, version: 2), params: { message: { id: message.id } }
    assert_redirected_to conversation_messages_url(message.conversation, version: 2)
  end

  test "should destroy message" do
    assert_difference("Message.count", -1) do
      delete message_url(@message)
    end

    assert_redirected_to conversation_messages_url(@conversation)
  end
end

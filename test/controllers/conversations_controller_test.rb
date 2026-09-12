require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @conversation = conversations(:greeting)
    login_as @conversation.user
  end

  test "should show conversation" do
    get conversation_url(@conversation)
    assert_response :success
  end

  test "should get edit" do
    get edit_conversation_url(@conversation)
    assert_response :success
  end

  test "should update conversation" do
    patch conversation_url(@conversation), params: {conversation: {assistant_id: @conversation.assistant_id, title: @conversation.title, user_id: @conversation.user_id}}
    assert_redirected_to conversation_url(@conversation)
  end

  test "should destroy conversation" do
    assert_difference("Conversation.count", -1) do
      delete conversation_url(@conversation)
    end

    assert_redirected_to root_url
  end

  test "reorder saves the order the ids arrive in" do
    user = @conversation.user
    ids = user.conversations.ordered.pluck(:id).rotate

    post reorder_conversations_url, params: { ids: ids }

    assert_response :no_content
    assert_equal ids, user.conversations.ordered.pluck(:id)
  end

  test "reorder leaves another user's conversations alone" do
    rob_conversation = conversations(:debugging)
    rob_conversation.update_column(:position, 42)

    post reorder_conversations_url, params: { ids: [rob_conversation.id] }

    assert_response :no_content
    assert_equal 42, rob_conversation.reload.position
  end
end

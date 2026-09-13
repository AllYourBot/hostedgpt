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

  test "index lists the user's conversations in position order" do
    user = @conversation.user
    ids = user.conversations.ordered.pluck(:id).rotate
    user.conversations.reposition(ids)

    get conversations_url

    assert_response :success
    assert_equal ids, assigns(:nav_conversations).pluck(:id)
  end

  test "a search-filtered sidebar is not drag-reorderable" do
    get conversations_url(query: "test")

    assert_response :success
    assert_no_match(/draggable="true"/, response.body)
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

  test "reorder accepts the string ids the browser sends" do
    user = @conversation.user
    ids = user.conversations.ordered.pluck(:id).rotate

    post reorder_conversations_url, params: { ids: ids.map(&:to_s) }

    assert_response :no_content
    assert_equal ids, user.conversations.ordered.pluck(:id)
  end

  test "reorder renumbers densely when the list includes ids it does not own" do
    user = @conversation.user
    keith_ids = user.conversations.ordered.pluck(:id)
    foreign = conversations(:debugging)
    foreign.update_column(:position, 42)

    post reorder_conversations_url, params: { ids: [foreign.id] + keith_ids.reverse }

    assert_response :no_content
    assert_equal 42, foreign.reload.position
    assert_equal keith_ids.reverse, user.conversations.ordered.pluck(:id)
    assert_equal (0...keith_ids.length).to_a, user.conversations.ordered.pluck(:position).sort
  end

  test "reorder with no ids param leaves everything alone" do
    user = @conversation.user
    before = user.conversations.ordered.pluck(:id, :position)

    post reorder_conversations_url

    assert_response :no_content
    assert_equal before, user.conversations.ordered.pluck(:id, :position)
  end

  test "reorder requires authentication" do
    get logout_path

    post reorder_conversations_url, params: { ids: [@conversation.id] }

    assert_redirected_to login_url
  end

  test "reorder leaves another user's conversations alone" do
    rob_conversation = conversations(:debugging)
    rob_conversation.update_column(:position, 42)

    post reorder_conversations_url, params: { ids: [rob_conversation.id] }

    assert_response :no_content
    assert_equal 42, rob_conversation.reload.position
  end
end

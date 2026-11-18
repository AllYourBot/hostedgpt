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

  # The sidebar loads this action inside its turbo frame, so the tests ask for it the same way.
  def get_nav_conversations(**params)
    get conversations_url, params: params, headers: { "Turbo-Frame" => "nav-conversations" }
  end

  test "index has no Pinned section when nothing is pinned" do
    get_nav_conversations

    assert_response :success
    assert_select "[data-role='pinned-header']", count: 0
    assert_select "#conversation-#{@conversation.id}", count: 1
  end

  test "index puts a pinned conversation in the Pinned section, above the time groups" do
    @conversation.pin!

    get_nav_conversations

    assert_response :success
    assert_select "[data-role='pinned-header']", count: 1
    assert_select "[data-role='pinned-header'] + [data-role='conversation'] #conversation-#{@conversation.id}", count: 1
  end

  test "index lists a pinned conversation only once" do
    @conversation.pin!

    get_nav_conversations

    assert_select "#conversation-#{@conversation.id}", count: 1
  end

  test "index does not show another user's pinned conversation" do
    conversations(:debugging).pin!

    get_nav_conversations

    assert_select "[data-role='pinned-header']", count: 0
    assert_select "#conversation-#{conversations(:debugging).id}", count: 0
  end

  test "index hides the Pinned section while searching, and still finds the pinned conversation" do
    @conversation.pin!

    get_nav_conversations(query: "Samantha")

    assert_select "[data-role='pinned-header']", count: 0
    assert_select "#conversation-#{@conversation.id}", count: 1
  end

  test "the options menu offers Pin for an unpinned conversation" do
    get_nav_conversations

    assert_select "#conversation-#{@conversation.id} [data-role='pin']", count: 1
    assert_select "#conversation-#{@conversation.id} [data-role='unpin']", count: 0
  end

  test "the options menu offers Unpin for a pinned conversation" do
    @conversation.pin!

    get_nav_conversations

    assert_select "#conversation-#{@conversation.id} [data-role='unpin']", count: 1
    assert_select "#conversation-#{@conversation.id} [data-role='pin']", count: 0
  end
end

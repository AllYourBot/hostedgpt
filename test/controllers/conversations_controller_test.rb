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
    assert_select "[data-role='pinned-header'] + [data-controller='sortable'] #conversation-#{@conversation.id}", count: 1
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

  test "index makes the pinned conversations draggable" do
    @conversation.pin!

    get_nav_conversations

    assert_select "[data-controller='sortable'] [data-sortable-id='#{@conversation.id}'][draggable='true']", count: 1
  end

  test "index does not make unpinned conversations draggable" do
    get_nav_conversations

    assert_select "[data-sortable-target='item']", count: 0
  end

  test "index does not make conversations draggable while searching" do
    @conversation.pin!

    get_nav_conversations(query: "Samantha")

    assert_select "[data-sortable-target='item']", count: 0
  end

  test "reorder saves the order the ids arrive in" do
    ids = %i[greeting ruby_version attachment].map { |name| conversations(name).tap(&:pin!).id }

    post reorder_conversations_url, params: { ids: ids }

    assert_response :no_content
    assert_equal ids, users(:keith).conversations.pinned.pluck(:id)
  end

  test "reorder leaves another user's conversations alone" do
    rob_conversation = conversations(:debugging)
    rob_conversation.pin!
    original_position = rob_conversation.pin_position

    post reorder_conversations_url, params: { ids: [rob_conversation.id] }

    assert_response :no_content
    assert_equal original_position, rob_conversation.reload.pin_position
  end

  test "reorder without ids changes nothing" do
    @conversation.pin!
    original_position = @conversation.pin_position

    post reorder_conversations_url

    assert_response :no_content
    assert_equal original_position, @conversation.reload.pin_position
  end
end

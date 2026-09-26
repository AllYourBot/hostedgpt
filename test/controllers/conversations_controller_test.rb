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

  test "index lists the user's unpinned conversations in position order with no drag when nothing is pinned" do
    user = @conversation.user
    ids = user.conversations.ordered.pluck(:id).rotate
    Conversation.reposition(user, ids)

    get conversations_url

    assert_response :success
    assert_equal ids, assigns(:nav_conversations).pluck(:id)
    assert_empty assigns(:pinned_conversations)
    # Pins carry the only hand order: unpinned rows expose no drop targets.
    assert_no_match(/pointerdown->sortable#press/, response.body)
  end

  test "a search-filtered sidebar is not drag-reorderable" do
    get conversations_url(query: "test")

    assert_response :success
    assert_no_match(/pointerdown->sortable#press/, response.body)
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

  test "pin persists and moves the conversation into the pinned section" do
    assert_not @conversation.pinned?(@conversation.user)

    post pin_conversation_url(@conversation)

    assert_response :no_content
    assert @conversation.reload.pinned?(@conversation.user)
    assert_includes Conversation.pinned_for(@conversation.user).map(&:id), @conversation.id
    assert_not_includes Conversation.unpinned_for(@conversation.user).map(&:id), @conversation.id
  end

  test "unpin persists and returns the conversation to recency order" do
    @conversation.pin!(@conversation.user)
    assert @conversation.pinned?(@conversation.user)

    post unpin_conversation_url(@conversation)

    assert_response :no_content
    assert_not @conversation.reload.pinned?(@conversation.user)
    assert_not_includes Conversation.pinned_for(@conversation.user).map(&:id), @conversation.id
    assert_includes Conversation.unpinned_for(@conversation.user).map(&:id), @conversation.id
  end

  test "double pin via the endpoint is idempotent" do
    post pin_conversation_url(@conversation)
    assert_response :no_content

    assert_no_difference "Pin.count" do
      post pin_conversation_url(@conversation)
    end

    assert_response :no_content
    assert @conversation.reload.pinned?(@conversation.user)
  end

  test "pin ignores a conversation the user does not own" do
    foreign = conversations(:debugging)

    assert_no_difference "Pin.count" do
      post pin_conversation_url(foreign)
    end

    assert_response :no_content
    assert_not foreign.reload.pinned?(@conversation.user)
    assert_empty Conversation.pinned_for(@conversation.user)
  end

  test "pin requires authentication" do
    get logout_path

    post pin_conversation_url(@conversation)

    assert_redirected_to login_url
  end

  test "unpin requires authentication" do
    get logout_path

    post unpin_conversation_url(@conversation)

    assert_redirected_to login_url
  end

  test "reorder with pinned ids persists order within pins and leaves unpinned alone" do
    user = @conversation.user
    pinned = user.conversations.ordered.limit(2).to_a
    pinned.each { |c| c.pin!(user) }
    unpinned_before = Conversation.unpinned_for(user).ordered.pluck(:id, :position)

    post reorder_conversations_url, params: { ids: pinned.reverse.map(&:id) }

    assert_response :no_content
    assert_equal pinned.reverse.map(&:id), Conversation.pinned_for(user).pluck(:id)
    assert_equal unpinned_before, Conversation.unpinned_for(user).ordered.pluck(:id, :position)
  end

  test "index renders the pinned section first with drag only on pins" do
    user = @conversation.user
    pinned = user.conversations.ordered.limit(2).to_a
    pinned.each { |c| c.pin!(user) }
    Conversation.reposition(user, pinned.map(&:id))

    get conversations_url

    assert_response :success
    assert_equal pinned.map(&:id), assigns(:pinned_conversations).pluck(:id)
    assert_not_includes assigns(:nav_conversations).map(&:id), pinned.first.id

    body = response.body
    first_pinned = body.index(pinned.first.title)
    first_unpinned = body.index(assigns(:nav_conversations).first.title)
    assert first_pinned < first_unpinned, "pinned section should render above unpinned"

    assert_match(/id="pinned-conversations"/, body)
    pinned_block = body[/<turbo-frame id="pinned-conversations".*?<\/turbo-frame>/m]
    assert_match(/pointerdown->sortable#press/, pinned_block)
    unpinned_block = body[/<turbo-frame id="conversations".*?<\/turbo-frame>/m]
    assert_no_match(/pointerdown->sortable#press/, unpinned_block)
  end

  test "index exposes a pin toggle distinct from the bookmark icon" do
    @conversation.pin!(@conversation.user)

    get conversations_url

    assert_response :success
    # Pin toggle posts to the pin/unpin member endpoints; the bookmark icon ships in a later
    # unit so its name must not appear yet. The pin icon itself is the map-pin heroicon, which
    # is visually distinct from the future bookmark icon (see _conversation.html.erb).
    assert_no_match(/bookmark/, response.body)
    assert_match(/data-role="unpin"/, response.body)
    assert_match(/data-role="pin"/, response.body)
    assert_match(%r{/conversations/#{@conversation.id}/(un)?pin}, response.body)
  end

  test "a search-filtered sidebar with pins exposes no drag" do
    @conversation.pin!(@conversation.user)

    get conversations_url(query: "test")

    assert_response :success
    assert_no_match(/pointerdown->sortable#press/, response.body)
  end
end

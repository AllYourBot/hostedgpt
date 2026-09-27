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

  test "index lists unpinned conversations in recency groups with pins excluded and no drag" do
    user = @conversation.user
    old = conversations(:ruby_version)
    old.update_column(:updated_at, 1.month.ago)
    pinned = conversations(:attachment)
    pinned.pin!(user)

    get conversations_url

    assert_response :success
    nav_ids = assigns(:nav_conversations).map(&:id)
    assert_not_includes nav_ids, pinned.id
    assert_equal user.conversations.unpinned_for(user).order(updated_at: :desc, id: :desc).pluck(:id), nav_ids

    body = response.body
    assert_match(/id="pinned-conversations"/, body)
    assert_match(/data-role="time-group"/, body)
    assert body.index(pinned.title) < body.index("Today"), "pinned section should render above the groups"
    assert body.index("Today") < body.index("This Month"), "groups should render in recency order"
    assert body.index("This Month") < body.index(old.title), "stale conversation should render under its group"

    pinned_block = body[/<turbo-frame id="pinned-conversations".*?<\/turbo-frame>/m]
    assert_match(/pointerdown->sortable#press/, pinned_block)
    unpinned_block = body[/<turbo-frame id="conversations".*?<\/turbo-frame>/m]
    assert_no_match(/pointerdown->sortable#press/, unpinned_block)
  end

  test "a search-filtered sidebar stays flat and is not drag-reorderable" do
    get conversations_url(query: "test")

    assert_response :success
    assert_not_empty assigns(:nav_conversations)
    assert_no_match(/data-role="time-group"/, response.body)
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

  test "reorder saves the order the pinned ids arrive in" do
    user = @conversation.user
    user.conversations.each { |conversation| conversation.pin!(user) }
    ids = user.conversations.pinned_for(user).pluck(:id).rotate

    post reorder_conversations_url, params: { ids: ids }

    assert_response :no_content
    assert_equal ids, user.conversations.pinned_for(user).pluck(:id)
  end

  test "reorder accepts the string ids the browser sends" do
    user = @conversation.user
    user.conversations.each { |conversation| conversation.pin!(user) }
    ids = user.conversations.pinned_for(user).pluck(:id).rotate

    post reorder_conversations_url, params: { ids: ids.map(&:to_s) }

    assert_response :no_content
    assert_equal ids, user.conversations.pinned_for(user).pluck(:id)
  end

  test "reorder renumbers densely when the list includes ids it does not own" do
    user = @conversation.user
    user.conversations.each { |conversation| conversation.pin!(user) }
    keith_ids = user.conversations.pinned_for(user).pluck(:id)
    foreign = conversations(:debugging)
    foreign.update_column(:position, 42)

    post reorder_conversations_url, params: { ids: [foreign.id] + keith_ids.reverse }

    assert_response :no_content
    assert_equal 42, foreign.reload.position
    assert_equal keith_ids.reverse, user.conversations.pinned_for(user).pluck(:id)
    assert_equal (0...keith_ids.length).to_a, user.conversations.pinned_for(user).pluck(:position).sort
  end

  test "reorder ignores unpinned ids, leaving hand order to the pinned section" do
    user = @conversation.user
    before = user.conversations.ordered.pluck(:id, :position)

    post reorder_conversations_url, params: { ids: user.conversations.pluck(:id) }

    assert_response :no_content
    assert_equal before, user.conversations.ordered.pluck(:id, :position)
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

  test "pin answers a nav morph to Turbo requests so the toggle visibly lands" do
    post pin_conversation_url(@conversation),
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    assert_match(/action="update" target="nav-conversations"/, response.body)
    assert_match(/data-role="unpin"/, response.body)
    assert @conversation.reload.pinned?(@conversation.user)
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
    @conversation.bookmark!(@conversation.user)

    get conversations_url

    assert_response :success
    # Pin and bookmark are separate toggles: the pin posts to the pin/unpin member endpoints
    # with the map-pin heroicon, the bookmark posts to the bookmark/unbookmark endpoints with
    # the bookmark heroicon (see _conversation.html.erb). Distinct roles, paths, and titles.
    assert_match(/data-role="unpin"/, response.body)
    assert_match(/data-role="pin"/, response.body)
    assert_match(%r{/conversations/#{@conversation.id}/(un)?pin}, response.body)
    assert_match(/data-role="unbookmark"/, response.body)
    assert_match(/data-role="bookmark"/, response.body)
    assert_match(%r{/conversations/#{@conversation.id}/(un)?bookmark}, response.body)
    assert_match(/title="Unpin"/, response.body)
    assert_match(/title="Unbookmark"/, response.body)
  end

  test "a search-filtered sidebar with pins exposes no drag" do
    @conversation.pin!(@conversation.user)

    get conversations_url(query: "test")

    assert_response :success
    assert_no_match(/pointerdown->sortable#press/, response.body)
  end

  test "bookmark persists without touching order" do
    user = @conversation.user
    before = user.conversations.ordered.pluck(:id, :position)
    assert_not @conversation.bookmarked?(user)

    post bookmark_conversation_url(@conversation)

    assert_response :no_content
    assert @conversation.reload.bookmarked?(user)
    assert_includes Conversation.bookmarked_for(user).map(&:id), @conversation.id
    assert_equal before, user.conversations.ordered.pluck(:id, :position)
  end

  test "unbookmark persists without touching order" do
    user = @conversation.user
    @conversation.bookmark!(user)
    assert @conversation.bookmarked?(user)
    before = user.conversations.ordered.pluck(:id, :position)

    post unbookmark_conversation_url(@conversation)

    assert_response :no_content
    assert_not @conversation.reload.bookmarked?(user)
    assert_not_includes Conversation.bookmarked_for(user).map(&:id), @conversation.id
    assert_equal before, user.conversations.ordered.pluck(:id, :position)
  end

  test "double bookmark via the endpoint is idempotent" do
    post bookmark_conversation_url(@conversation)
    assert_response :no_content

    assert_no_difference "Bookmark.count" do
      post bookmark_conversation_url(@conversation)
    end

    assert_response :no_content
    assert @conversation.reload.bookmarked?(@conversation.user)
  end

  test "unbookmark when clear is a no-op" do
    assert_no_difference "Bookmark.count" do
      post unbookmark_conversation_url(@conversation)
    end

    assert_response :no_content
    assert_not @conversation.reload.bookmarked?(@conversation.user)
  end

  test "bookmark ignores a conversation the user does not own" do
    foreign = conversations(:debugging)

    assert_no_difference "Bookmark.count" do
      post bookmark_conversation_url(foreign)
    end

    assert_response :no_content
    assert_not foreign.reload.bookmarked?(@conversation.user)
    assert_empty Conversation.bookmarked_for(@conversation.user)
  end

  test "bookmark requires authentication" do
    get logout_path

    post bookmark_conversation_url(@conversation)

    assert_redirected_to login_url
  end

  test "unbookmark requires authentication" do
    get logout_path

    post unbookmark_conversation_url(@conversation)

    assert_redirected_to login_url
  end

  test "bookmarks view lists exactly the user's bookmarked conversations" do
    user = @conversation.user
    other = user.conversations.where.not(id: @conversation.id).first
    unbookmarked = user.conversations.where.not(id: [@conversation.id, other.id]).first
    foreign = conversations(:debugging)
    foreign.bookmark!(foreign.user)
    @conversation.bookmark!(user)
    other.bookmark!(user)
    @conversation.update_column(:updated_at, 1.day.ago)
    other.update_column(:updated_at, Time.current)

    get bookmarks_conversations_url

    assert_response :success
    assert_equal [other.id, @conversation.id], assigns(:nav_conversations).map(&:id)
    assert_not_includes assigns(:nav_conversations).map(&:id), unbookmarked.id
    assert_not_includes assigns(:nav_conversations).map(&:id), foreign.id
  end

  test "bookmarks view includes a pinned conversation once, outside the pinned section" do
    user = @conversation.user
    @conversation.pin!(user)
    @conversation.bookmark!(user)

    get bookmarks_conversations_url

    assert_response :success
    assert_equal [@conversation.id], assigns(:nav_conversations).map(&:id)
    assert_empty assigns(:pinned_conversations)
  end

  test "bookmarks view narrows by search query" do
    user = @conversation.user
    other = conversations(:attachment)
    assert_equal user, other.user
    @conversation.bookmark!(user)
    other.bookmark!(user)

    get bookmarks_conversations_url(query: "Samantha")

    assert_response :success
    assert_equal [@conversation.id], assigns(:nav_conversations).map(&:id)
  end

  test "bookmarks view explains itself when empty" do
    get bookmarks_conversations_url

    assert_response :success
    assert_empty assigns(:nav_conversations)
    assert_match(/data-role="empty-bookmarks"/, response.body)
  end

  test "reactions view explains itself when empty" do
    get reactions_conversations_url

    assert_response :success
    assert_empty assigns(:nav_conversations)
    assert_match(/data-role="empty-reactions"/, response.body)
  end

  test "pinned section carries a header when pins exist" do
    @conversation.pin!(@conversation.user)

    get conversations_url

    assert_response :success
    assert_match(/data-role="pinned-header"/, response.body)
  end

  test "bookmarks view exposes a link back and the sidebar links to it" do
    get bookmarks_conversations_url

    assert_response :success
    assert_match(%r{href="/conversations"}, response.body)

    get conversations_url

    assert_response :success
    assert_match(%r{href="/conversations/bookmarks"}, response.body)
  end

  test "react persists with counts and leaves order alone" do
    user = @conversation.user
    before = user.conversations.ordered.pluck(:id, :position)
    assert_not @conversation.user_reacted?("👍", user)

    post react_conversation_url(@conversation), params: { emoji: "👍" }

    assert_response :no_content
    assert @conversation.reload.user_reacted?("👍", user)
    assert_equal({ "👍" => 1 }, @conversation.reaction_counts)
    assert_includes Conversation.reacted_for(user).map(&:id), @conversation.id
    assert_equal before, user.conversations.ordered.pluck(:id, :position)
  end

  test "unreact persists and leaves order alone" do
    user = @conversation.user
    @conversation.react!("👍", user)
    before = user.conversations.ordered.pluck(:id, :position)

    post unreact_conversation_url(@conversation), params: { emoji: "👍" }

    assert_response :no_content
    assert_not @conversation.reload.user_reacted?("👍", user)
    assert_equal before, user.conversations.ordered.pluck(:id, :position)
  end

  test "double react via the endpoint is idempotent" do
    post react_conversation_url(@conversation), params: { emoji: "👍" }
    assert_response :no_content

    assert_no_difference "Reaction.count" do
      post react_conversation_url(@conversation), params: { emoji: "👍" }
    end

    assert_response :no_content
    assert_equal({ "👍" => 1 }, @conversation.reload.reaction_counts)
  end

  test "unreact when clear is a no-op" do
    assert_no_difference "Reaction.count" do
      post unreact_conversation_url(@conversation), params: { emoji: "👍" }
    end

    assert_response :no_content
  end

  test "react with a blank emoji is rejected" do
    assert_no_difference "Reaction.count" do
      post react_conversation_url(@conversation), params: { emoji: "" }
    end

    assert_response :unprocessable_content
  end

  test "react ignores a conversation the user does not own" do
    foreign = conversations(:debugging)

    assert_no_difference "Reaction.count" do
      post react_conversation_url(foreign), params: { emoji: "👍" }
    end

    assert_response :no_content
    assert_not foreign.reload.user_reacted?("👍", @conversation.user)
  end

  test "react requires authentication" do
    get logout_path

    post react_conversation_url(@conversation), params: { emoji: "👍" }

    assert_redirected_to login_url
  end

  test "unreact requires authentication" do
    get logout_path

    post unreact_conversation_url(@conversation), params: { emoji: "👍" }

    assert_redirected_to login_url
  end

  test "reacting never disturbs pinned order" do
    user = @conversation.user
    pinned = user.conversations.ordered.limit(2).to_a
    pinned.each { |c| c.pin!(user) }
    pin_order = Conversation.pinned_for(user).pluck(:id)

    post react_conversation_url(pinned.first), params: { emoji: "👍" }

    assert_response :no_content
    assert_equal pin_order, Conversation.pinned_for(user).pluck(:id)
  end

  test "reactions view lists reacted conversations newest reaction first" do
    user = @conversation.user
    other = user.conversations.where.not(id: @conversation.id).first
    third = user.conversations.where.not(id: [@conversation.id, other.id]).first
    foreign = conversations(:debugging)
    foreign.react!("👍", foreign.user)
    @conversation.react!("👍", user)
    other.react!("🎉", user)
    Reaction.where(user: user, reactable: @conversation).update_all(created_at: 2.days.ago)

    get reactions_conversations_url

    assert_response :success
    assert_equal [other.id, @conversation.id], assigns(:nav_conversations).map(&:id)
    assert_not_includes assigns(:nav_conversations).map(&:id), third.id
    assert_not_includes assigns(:nav_conversations).map(&:id), foreign.id
  end

  test "reactions view lists a conversation reacted through one of its messages" do
    user = @conversation.user
    @conversation.messages.first.react!("👍", user)

    get reactions_conversations_url

    assert_response :success
    assert_equal [@conversation.id], assigns(:nav_conversations).map(&:id)
  end

  test "reactions view orders a message reaction by its own recency" do
    user = @conversation.user
    other = user.conversations.where.not(id: @conversation.id).first
    @conversation.react!("👍", user)
    other.messages.first.react!("👍", user)
    Reaction.where(user: user, reactable: @conversation).update_all(created_at: 2.days.ago)

    get reactions_conversations_url

    assert_response :success
    assert_equal [other.id, @conversation.id], assigns(:nav_conversations).map(&:id)
  end

  test "reactions view narrows by search query" do
    user = @conversation.user
    other = conversations(:attachment)
    assert_equal user, other.user
    @conversation.react!("👍", user)
    other.react!("👍", user)

    get reactions_conversations_url(query: "Samantha")

    assert_response :success
    assert_equal [@conversation.id], assigns(:nav_conversations).map(&:id)
  end

  test "reactions view exposes a link back and the sidebar links to it" do
    get reactions_conversations_url

    assert_response :success
    assert_match(%r{href="/conversations"}, response.body)

    get conversations_url

    assert_response :success
    assert_match(%r{href="/conversations/reactions"}, response.body)
  end

  test "reactions view includes a pinned conversation once, outside the pinned section" do
    user = @conversation.user
    @conversation.pin!(user)
    @conversation.react!("👍", user)

    get reactions_conversations_url

    assert_response :success
    assert_equal [@conversation.id], assigns(:nav_conversations).map(&:id)
    assert_empty assigns(:pinned_conversations)
    assert_no_match(/pointerdown->sortable#press/, response.body)
  end

  test "index renders conversation reaction counts" do
    @conversation.react!("👍", @conversation.user)

    get conversations_url

    assert_response :success
    assert_match(/data-role="reaction-counts"/, response.body)
    assert_match(/👍/, response.body)
  end
end

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

  test "index shows a dot before an UNREAD conversation's title and none for a read one" do
    @conversation.update_column(:unread, true)
    read = conversations(:ruby_version)

    get_nav_conversations

    assert_select "#conversation-#{@conversation.id} > ##{dom_id(@conversation)}-unread[data-role='unread'] + a[data-role='title']", 1,
      "An unread conversation should show its dot just before the title"
    assert_select "#conversation-#{@conversation.id} ##{dom_id(@conversation)}-unread .sr-only", "Unread",
      "Screen readers should hear that it is unread"
    assert_select "#conversation-#{read.id} [data-role='unread']", 0, "A read conversation should show no dot"
  end

  test "index leads a BOOKMARKED conversation's title with its solid ribbon, and keeps an unbookmarked one's on hover" do
    @conversation.bookmark!(@conversation.user)
    unbookmarked = @conversation.user.conversations.where.not(id: @conversation.id).first

    get_nav_conversations

    assert_select "#conversation-#{@conversation.id} > ##{dom_id(@conversation)}-bookmark:first-child [data-role='unbookmark']", 1,
      "A bookmarked row should always show its solid ribbon, to the left of the title"
    assert_select "#conversation-#{unbookmarked.id} > div.hidden ##{dom_id(unbookmarked)}-bookmark [data-role='bookmark']", 1,
      "An unbookmarked row should only show its outline ribbon among the hover actions on the right"
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

  test "bookmark toggle answers a turbo-stream update targeting the nav frame" do
    post bookmark_conversation_url(@conversation), as: :turbo_stream

    assert_response :success
    assert_includes response.body, %(turbo-stream action="update" target="nav-conversations")
    assert_includes response.body, %(data-role="unbookmark")
    assert_select "form[action*='unbookmark'] svg path[d^='m14.74']", count: 0 # the trashcan is /bookmarks-only, even though row delete menus share the icon
    assert_select "div[data-role='conversation'].relationship" # the viewed row stays highlighted
    assert_includes response.body, %(targets="[data-conversation-bookmark-toggle-labeled=&#39;#{@conversation.id}&#39;]")
    assert_includes response.body, %(targets="[data-conversation-bookmark-toggle=&#39;#{@conversation.id}&#39;]")
    assert_select "form[action*='unbookmark'] svg path[d^='M6.32']", count: 3 # one sidebar row + two header instances
    assert_select "turbo-stream[targets*='-labeled'] span", text: I18n.t("app.conversations.ui.bookmark") # the labeled variant keeps its visible label
    assert_select "turbo-stream[targets]:not([targets*='-labeled']) span", text: I18n.t("app.conversations.ui.bookmark"), count: 0 # the plain variant's only span is the icon's sizing wrapper, never a label
    assert @conversation.bookmarked?(@conversation.user)
  end

  test "unbookmark toggle answers a turbo-stream update and removes the bookmark" do
    @conversation.bookmark!(@conversation.user)

    post unbookmark_conversation_url(@conversation), as: :turbo_stream

    assert_response :success
    assert_includes response.body, %(turbo-stream action="update" target="nav-conversations")
    assert_includes response.body, %(data-role="bookmark")
    assert_not @conversation.bookmarked?(@conversation.user)
  end

  test "non-JS toggle post answers 204 no content" do
    post bookmark_conversation_url(@conversation)

    assert_response :no_content
    assert @conversation.bookmarked?(@conversation.user)
  end

  test "toggle with an active search keeps the query in the re-rendered form and the filter intact" do
    post bookmark_conversation_url(@conversation), params: {query: "hear"}, as: :turbo_stream

    assert_response :success
    assert_includes response.body, 'value="hear"'
    assert_includes response.body, "Meeting Samantha"
    assert_not_includes response.body, "Ruby version"
  end

  test "bookmarking another user's conversation is a 404 and bookmarks nothing" do
    foreign = conversations(:debugging)

    assert_no_difference "Bookmark.count" do
      post bookmark_conversation_url(foreign)
    end

    assert_response :not_found
    assert_not foreign.bookmarked?(foreign.user)
  end

  test "toggling leaves updated_at and sidebar grouping untouched" do
    assert_no_changes -> { @conversation.reload.updated_at } do
      post bookmark_conversation_url(@conversation)
      post unbookmark_conversation_url(@conversation)
    end
  end

  test "unauthenticated toggle post redirects to login" do
    reset!

    post bookmark_conversation_url(@conversation)

    assert_redirected_to login_path
  end

  test "the bookmarks page lists bookmarked conversations and messages in bookmark-recency order" do
    conversations(:ruby_version).bookmark!(@conversation.user) # oldest bookmark
    messages(:yes_i_do).bookmark!(@conversation.user)
    @conversation.bookmark!(@conversation.user) # newest bookmark

    get bookmarked_page_path

    assert_response :success
    assert_select "li[data-role='bookmarked-conversation']", count: 2
    assert_select "li[data-role='bookmarked-message']", count: 1
    assert_select "li[data-role='bookmarked-conversation'] svg path[d^='m14.74']", count: 2 # the trashcan affordance, not a solid bookmark
    assert_select "li[data-role='bookmarked-message'] svg path[d^='m14.74']", count: 1
    assert_select "li[data-role='bookmarked-conversation'] button[title=?]", I18n.t("app.conversations.ui.unbookmark_conversation"), count: 2
    conversation_titles = css_select("li[data-role='bookmarked-conversation'] a[data-role='bookmarked-conversation-link']").map { |link| link.text.strip }
    assert_equal ["Meeting Samantha", "Ruby version"], conversation_titles
  end

  test "a bookmarked message entry links into its conversation at that message and version" do
    message = messages(:yes_i_do)
    message.bookmark!(@conversation.user)

    get bookmarked_page_path

    assert_response :success
    assert_select "a[data-role='bookmarked-message-link'][href=?]",
      conversation_messages_path(message.conversation, version: message.version, anchor: "message_#{message.id}")
  end

  test "landing on a bookmarked message's deep link renders that message's version" do
    message = messages(:message2_v1)
    message.bookmark!(message.user)

    get conversation_messages_url(message.conversation, version: message.version, anchor: "message_#{message.id}")

    assert_response :success
    assert_select "#message_#{message.id}"
    assert_select "#message_#{messages(:message2_v2).id}", count: 0
  end

  test "unbookmarking from the page removes the entry in place and refreshes the nav frame" do
    @conversation.bookmark!(@conversation.user)
    bookmark = @conversation.user.bookmarks.find_by(bookmarkable: @conversation)

    post unbookmark_conversation_url(@conversation), params: {from_bookmarks: true}, as: :turbo_stream

    assert_response :success
    assert_includes response.body, %(turbo-stream action="remove" target="#{dom_id(bookmark)}")
    assert_includes response.body, %(turbo-stream action="update" target="nav-conversations")
    assert_not @conversation.bookmarked?(@conversation.user)
  end

  test "unbookmarking from the page with a stale (already-removed) entry converges with a refresh" do
    post unbookmark_conversation_url(@conversation), params: {from_bookmarks: true}, as: :turbo_stream

    assert_response :success
    assert_includes response.body, %(turbo-stream action="refresh")
    assert_not @conversation.bookmarked?(@conversation.user)
  end

  test "a blank-content bookmarked message renders the role-label fallback, not a blank row" do
    message = messages(:yes_i_do)
    message.update_columns(content_text: nil)
    message.bookmark!(@conversation.user)

    get bookmarked_page_path

    assert_response :success
    assert_includes response.body, I18n.t("app.conversations.ui.message_no_content", name: "Samantha")
  end

  test "zero bookmarks renders the empty state" do
    get bookmarked_page_path

    assert_response :success
    assert_select "[data-role='empty-bookmarks']"
  end

  test "the chat header carries a stateful bookmark toggle for the viewed conversation" do
    get conversation_messages_url(@conversation, version: 1)

    assert_response :success
    assert_select "[data-conversation-bookmark-toggle-labeled='#{@conversation.id}'] form[action*='bookmark'] svg path[d^='M17.593']" # outline while not bookmarked
    assert_select "[data-conversation-bookmark-toggle-labeled='#{@conversation.id}'] span", text: I18n.t("app.conversations.ui.bookmark")
    assert_select "[data-conversation-bookmark-toggle='#{@conversation.id}'] form[action*='bookmark'] svg path[d^='M17.593']" # outline while not bookmarked
  end

  test "the chat header's toggle shows the solid bookmark and the reverse action once bookmarked" do
    @conversation.bookmark!(@conversation.user)

    get conversation_messages_url(@conversation, version: 1)

    assert_select "[data-conversation-bookmark-toggle-labeled='#{@conversation.id}'] form[action*='unbookmark'] svg path[d^='M6.32']" # solid while bookmarked
    assert_select "[data-conversation-bookmark-toggle='#{@conversation.id}'] form[action*='unbookmark'] svg path[d^='M6.32']" # solid while bookmarked
  end

  test "another user's bookmarks never appear" do
    conversations(:debugging).bookmark!(users(:rob))

    get bookmarked_page_path

    assert_select "[data-role='empty-bookmarks']"
  end
end

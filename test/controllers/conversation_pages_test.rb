require "test_helper"

# U9: full card pages for pinned, bookmarked, and reacted collections. Each page reuses the
# sidebar nav scopes, so ordering and cross-user isolation match the filtered sidebar views.
# Card toggles answer card-replacement streams targeting the card dom-id.
class ConversationPagesTest < ActionDispatch::IntegrationTest
  setup do
    @conversation = conversations(:greeting)
    login_as @conversation.user
  end

  test "pinned page lists exactly the user's pins in hand order with working title links" do
    user = @conversation.user
    first = conversations(:greeting)
    second = conversations(:attachment)
    first.pin!(user)
    second.pin!(user)
    Conversation.reposition(user, [second.id, first.id])

    get pinned_page_url

    assert_response :success
    assert_equal [second.id, first.id], assigns(:pinned_conversations).map(&:id)

    body = response.body
    assert_match(/data-role="conversation-card"/, body)
    assert body.index(second.title) < body.index(first.title), "pins should render in hand order"
    assert_match(%r{href="/conversations/#{second.id}/messages"}, body)
    assert_match(/id="card_conversation_#{second.id}"/, body)
  end

  test "pinned page isolates other users pins" do
    foreign = conversations(:debugging)
    foreign.pin!(foreign.user)

    get pinned_page_url

    assert_response :success
    assert_empty assigns(:pinned_conversations)
    assert_match(/data-role="empty-pins"/, body = response.body)
    assert_match(/#{Regexp.escape(I18n.t("app.conversations.ui.no_pins_yet"))}/, body)
  end

  test "bookmarked page lists exactly the user's bookmarks in recency order" do
    user = @conversation.user
    other = user.conversations.where.not(id: @conversation.id).first
    foreign = conversations(:debugging)
    foreign.bookmark!(foreign.user)
    @conversation.bookmark!(user)
    other.bookmark!(user)
    @conversation.update_column(:updated_at, 1.day.ago)
    other.update_column(:updated_at, Time.current)

    get bookmarked_page_url

    assert_response :success
    assert_equal [other.id, @conversation.id], assigns(:bookmarked_conversations).map(&:id)
    assert_not_includes assigns(:bookmarked_conversations).map(&:id), foreign.id

    body = response.body
    assert body.index(other.title) < body.index(@conversation.title)
    assert_match(%r{href="/conversations/#{other.id}/messages"}, body)
    assert_match(/id="card_conversation_#{other.id}"/, body)
  end

  test "bookmarked page reuses the empty bookmarks state when empty" do
    get bookmarked_page_url

    assert_response :success
    assert_empty assigns(:bookmarked_conversations)
    assert_match(/data-role="empty-bookmarks"/, response.body)
    assert_match(/#{Regexp.escape(I18n.t("app.conversations.ui.no_bookmarks_yet"))}/, response.body)
  end

  test "reacted page lists reacted conversations newest reaction first with isolation" do
    user = @conversation.user
    other = user.conversations.where.not(id: @conversation.id).first
    foreign = conversations(:debugging)
    foreign.react!("👍", foreign.user)
    @conversation.react!("👍", user)
    other.react!("🎉", user)
    Reaction.where(user: user, reactable: @conversation).update_all(created_at: 2.days.ago)

    get reacted_page_url

    assert_response :success
    assert_equal [other.id, @conversation.id], assigns(:reacted_conversations).map(&:id)
    assert_not_includes assigns(:reacted_conversations).map(&:id), foreign.id

    body = response.body
    assert body.index(other.title) < body.index(@conversation.title)
    assert_match(/id="card_conversation_#{other.id}"/, body)
  end

  test "reacted page reuses the empty reactions state when empty" do
    get reacted_page_url

    assert_response :success
    assert_empty assigns(:reacted_conversations)
    assert_match(/data-role="empty-reactions"/, response.body)
    assert_match(/#{Regexp.escape(I18n.t("app.conversations.ui.no_reactions_yet"))}/, response.body)
  end

  test "card bookmark toggle on the pinned page replaces the card in place" do
    user = @conversation.user
    @conversation.pin!(user)

    post bookmark_conversation_url(@conversation),
      params: { page_context: "pinned" },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    card_id = "card_conversation_#{@conversation.id}"
    assert_match(/action="replace" target="#{card_id}"/, response.body)
    assert_match(/id="#{card_id}"/, response.body)
    assert_match(/data-role="unbookmark"/, response.body)
    assert @conversation.reload.bookmarked?(user)

    # The stream target exists on the page itself.
    get pinned_page_url
    assert_match(/id="#{card_id}"/, response.body)
  end

  test "card unpin on the pinned page removes the card" do
    user = @conversation.user
    @conversation.pin!(user)

    post unpin_conversation_url(@conversation),
      params: { page_context: "pinned" },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    assert_match(/action="remove" target="card_conversation_#{@conversation.id}"/, response.body)
    assert_not @conversation.reload.pinned?(user)
  end

  test "card unbookmark on the bookmarked page removes the card" do
    user = @conversation.user
    @conversation.bookmark!(user)

    post unbookmark_conversation_url(@conversation),
      params: { page_context: "bookmarked" },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    assert_match(/action="remove" target="card_conversation_#{@conversation.id}"/, response.body)
  end

  test "card pin toggle on the bookmarked page replaces the card in place" do
    user = @conversation.user
    @conversation.bookmark!(user)

    post pin_conversation_url(@conversation),
      params: { page_context: "bookmarked" },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    card_id = "card_conversation_#{@conversation.id}"
    assert_match(/action="replace" target="#{card_id}"/, response.body)

    get bookmarked_page_url
    assert_match(/id="#{card_id}"/, response.body)
  end

  test "card pin toggle on the reacted page replaces the card in place" do
    user = @conversation.user
    @conversation.react!("👍", user)

    post pin_conversation_url(@conversation),
      params: { page_context: "reacted" },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    card_id = "card_conversation_#{@conversation.id}"
    assert_match(/action="replace" target="#{card_id}"/, response.body)

    get reacted_page_url
    assert_match(/id="#{card_id}"/, response.body)
  end

  test "card toggle ignores a conversation the user does not own" do
    foreign = conversations(:debugging)

    assert_no_difference "Pin.count" do
      post pin_conversation_url(foreign), params: { page_context: "pinned" }
    end

    assert_response :no_content
  end

  test "sidebar carries open-page buttons that navigate full-page, not frame-scoped" do
    @conversation.pin!(@conversation.user)

    get conversations_url

    assert_response :success
    body = response.body
    assert_match(/data-role="open-pinned-page"/, body)
    assert_match(/data-role="open-bookmarks-page"/, body)
    assert_match(/data-role="open-reactions-page"/, body)
    assert_match(%r{href="/pinned"}, body)
    assert_match(%r{href="/bookmarks"}, body)
    assert_match(%r{href="/reactions"}, body)
    assert_match(/data-turbo-frame="_top"/, body)
  end
end

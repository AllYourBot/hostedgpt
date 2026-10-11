require "application_system_test_case"

# The picker opens on demand and posts the chosen emoji without navigating: it may live
# inside a sortable row, since the sortable ghost clone strips Stimulus wiring from its
# scenery copy only and the row's own controller stays connected through drags and morphs.
# Sidebar conversation rows carry the full picker with counts beside it, same partial as
# messages (see the controller tests for the endpoints).
class ReactionsTest < ApplicationSystemTestCase
  test "picker opens on a message and selecting an emoji reacts without navigating" do
    user = users(:keith)
    conversation = conversations(:greeting)
    message = messages(:im_a_bot)

    login_as(user)
    visit_and_scroll_wait conversation_messages_path(conversation, version: 1)

    row = find("#message_#{message.id}")
    assert_no_match(/👍/, row.find("[data-role='reaction-counts']").text)

    row.find("[data-role='react']").click
    assert row.find("[data-emoji-picker-target='panel']").visible?

    path_before = current_path
    row.find("[data-role='react-emoji']", text: "👍").click

    assert_true "the count should render after selecting an emoji" do
      row.find("[data-role='reaction-counts']").text.include?("👍 1")
    end
    assert_equal path_before, current_path
    assert_true "the reaction should persist" do
      message.reload.user_reacted?("👍", user)
    end

    # Selecting the same emoji again unreacts: the chip disappears, still without navigating.
    row.find("[data-role='react']").click
    row.find("[data-role='react-emoji']", text: "👍").click

    assert_true "the count should clear after unreacting" do
      !row.find("[data-role='reaction-counts']").text.include?("👍")
    end
    assert_equal path_before, current_path
    assert_true "the reaction should be gone" do
      !message.reload.user_reacted?("👍", user)
    end
  end

  test "opening a second picker closes the first, and outside click closes the panel" do
    user = users(:keith)
    conversation = conversations(:greeting)
    first = messages(:hear_me)
    second = messages(:yes_i_do)

    login_as(user)
    visit_and_scroll_wait conversation_messages_path(conversation, version: 1)

    # The row action bar is invisible except on the last message, so panels assert through
    # their hidden class rather than visibility, and clicks dispatch via JS for the same reason.
    first_panel = find("#message_#{first.id} [data-emoji-picker-target='panel']", visible: :all)
    second_panel = find("#message_#{second.id} [data-emoji-picker-target='panel']", visible: :all)
    first_button = find("#message_#{first.id} [data-role='react']", visible: :all)
    second_button = find("#message_#{second.id} [data-role='react']", visible: :all)

    page.execute_script("arguments[0].click()", first_button)
    assert_not_includes first_panel[:class], "hidden"

    page.execute_script("arguments[0].click()", second_button)
    assert_not_includes second_panel[:class], "hidden"
    assert_includes first_panel[:class], "hidden"

    page.execute_script("document.body.click()")
    assert_includes second_panel[:class], "hidden"
  end

  test "reacting to an emoji with an existing count increments it" do    user = users(:keith)
    other = users(:rob)
    conversation = conversations(:greeting)
    message = messages(:im_a_bot)
    message.react!("👍", other)

    login_as(user)
    visit_and_scroll_wait conversation_messages_path(conversation, version: 1)

    row = find("#message_#{message.id}")
    assert_match(/👍 1/, row.find("[data-role='reaction-counts']").text)

    row.find("[data-role='react']").click
    row.find("[data-role='react-emoji']", text: "👍").click

    assert_true "the count should increment" do
      row.find("[data-role='reaction-counts']").text.include?("👍 2")
    end
    assert_true "both reactions should persist" do
      message.reload.user_reacted?("👍", user) && message.reload.user_reacted?("👍", other)
    end
  end

  test "sidebar picker reacts on a pinned row and pin order survives" do    user = users(:keith)
    conversation = conversations(:greeting)
    conversation.pin!(user)

    login_as(user)
    visit root_path

    row = find("#conversation_#{conversation.id}")
    row.find("[data-role='react-conversation']").click
    row.find("[data-role='react-emoji-conversation']", text: "🎉").click

    assert_true "the sidebar chip should render" do
      row.find("[data-role='reaction-counts']").text.include?("🎉 1")
    end
    assert_true "the reaction should persist" do
      conversation.reload.user_reacted?("🎉", user)
    end
    assert_equal [conversation.id], Conversation.pinned_for(user).pluck(:id)
  end

  test "pinning a message shows the pinned section without a reload" do
    user = users(:keith)
    conversation = conversations(:greeting)
    message = messages(:im_a_bot)

    login_as(user)
    visit_and_scroll_wait conversation_messages_path(conversation, version: 1)

    row = find("#message_#{message.id}")
    row.hover
    row.find("[data-role='pin-message']").click

    assert_selector("#pinned-messages")
    assert message.reload.pinned?(user)
  end

  test "unpinning a message drops the pinned section without a reload" do
    user = users(:keith)
    conversation = conversations(:greeting)
    message = messages(:im_a_bot)
    message.pin!(user)

    login_as(user)
    visit_and_scroll_wait conversation_messages_path(conversation, version: 1)

    assert_selector("#pinned-messages [data-role='pinned-message']")
    find("#pinned-messages [data-role='unpin-message']").click

    assert_no_selector("[data-role='pinned-message']")
    assert_not message.reload.pinned?(user)
  end

  test "bookmarking a message flips the icon without a reload" do
    user = users(:keith)
    conversation = conversations(:greeting)
    message = messages(:im_a_bot)

    login_as(user)
    visit_and_scroll_wait conversation_messages_path(conversation, version: 1)

    row = find("#message_#{message.id}")
    row.hover
    row.find("[data-role='bookmark-message']").click

    assert_selector("#message_#{message.id} [data-role='unbookmark-message']")
    assert message.reload.bookmarked?(user)

    find("#message_#{message.id} [data-role='unbookmark-message']").click

    assert_selector("#message_#{message.id} [data-role='bookmark-message']")
    assert_not message.reload.bookmarked?(user)
  end

  test "message action buttons line up in one horizontal row" do
    user = users(:keith)
    conversation = conversations(:greeting)
    message = messages(:im_a_bot)

    login_as(user)
    visit_and_scroll_wait conversation_messages_path(conversation, version: 1)

    # A single bounding-rect snapshot can catch mid-paint layout, so sample inside the
    # polling assert until all five buttons render within one row's tolerance together.
    assert_true "expected all five action buttons to render in one horizontal row" do
      tops = page.evaluate_script(
        "(function(){ return ['react', 'pin-message', 'bookmark-message', 'clipboard', 'regenerate'].map(function(role){" \
        "var el = document.querySelector('#message_#{message.id} [data-role=\"' + role + '\"]');" \
        "return el ? Math.round(el.getBoundingClientRect().top) : -1; }); }).call(this)".gsub('#{message.id}', message.id.to_s)
      )

      !tops.include?(-1) && tops.max - tops.min <= 10
    end
  end
end

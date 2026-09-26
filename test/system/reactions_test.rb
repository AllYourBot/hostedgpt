require "application_system_test_case"

# The message picker opens on demand and posts the chosen emoji without navigating: the row it
# lives on is never a sortable item, so the sortable ghost clone can never strip its wiring.
# Sidebar conversation rows render counts only (see the controller tests for the endpoints).
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

  test "reacting to an emoji with an existing count increments it" do
    user = users(:keith)
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
end

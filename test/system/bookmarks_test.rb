require "application_system_test_case"

class BookmarksTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    visit root_path
  end

  test "bookmarking a conversation and a message lists them on /bookmarks with a working deep link" do
    # Bookmark a conversation from the sidebar row: hover reveals the row's controls.
    conversation_row = find("[data-role='conversation']", match: :first)
    conversation_row.hover
    conversation_row.find("[data-role='bookmark']").click
    assert_selector("[data-role='unbookmark']") # the toggle flips in place

    # Bookmark the conversation's last message from its action bar.
    conversation_row.find("[data-role='title']").click
    assert_selector("[data-role='bookmark-message']")
    first("[data-role='bookmark-message']").click
    assert_selector("[data-role='unbookmark-message']")

    # Both entries show on the /bookmarks page.
    click_element "a[data-role='open-bookmarks-page']"
    assert_selector("[data-role='bookmarked-conversation']")
    assert_selector("[data-role='bookmarked-message']")

    # The message deep link lands on that message in the conversation.
    click_element("[data-role='bookmarked-message-link']")
    assert_selector("[data-role='message']")

    # Unbookmarking from the page removes the entry in place.
    click_element "a[data-role='open-bookmarks-page']"
    find("[data-role='bookmarked-message'] [data-role='unbookmark-message']").click
    assert_no_selector("[data-role='bookmarked-message']")
  end

  test "the bookmarks page shows an empty state when nothing is bookmarked" do
    click_element "a[data-role='open-bookmarks-page']"

    assert_selector("[data-role='empty-bookmarks']")
  end
end

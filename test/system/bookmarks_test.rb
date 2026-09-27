require "application_system_test_case"

# Bookmark toggles and views, driven through the real browser: the controller tests prove the
# server saves, but only these prove the click submits and the sidebar updates without a reload.
class BookmarksTest < ApplicationSystemTestCase
  test "toggling the bookmark icon flips it without a reload" do
    user = users(:keith)
    conversation = conversations(:greeting)

    login_as(user)
    visit root_path

    find("#conversation_#{conversation.id} [data-role='bookmark']").click

    assert_selector("#conversation_#{conversation.id} [data-role='unbookmark']")
    assert conversation.reload.bookmarked?(user)
  end

  test "bookmarks view lists bookmarked conversations with a way back" do    user = users(:keith)
    conversation = conversations(:greeting)
    conversation.bookmark!(user)

    login_as(user)
    visit root_path

    find("[data-role='bookmarks-link']").click

    assert_selector("#conversation_#{conversation.id}")
    find("[data-role='all-conversations']").click

    assert_selector("[data-role='bookmarks-link']")
  end

  test "clicking reactions shows reacted conversations with a way back" do
    user = users(:keith)
    conversation = conversations(:greeting)
    conversation.react!("🎉", user)

    login_as(user)
    visit root_path

    find("[data-role='reactions-link']").click

    assert_selector("#conversation_#{conversation.id}")
    find("[data-role='all-conversations']").click

    assert_selector("[data-role='reactions-link']")
  end
end

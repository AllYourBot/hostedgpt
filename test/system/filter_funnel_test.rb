require "application_system_test_case"

# U9 funnel minimal slice, driven through the real browser: the controller tests prove the
# server scopes, but only these prove the button labels, the one-tap All/clear, the legacy
# sync, and the reload reset land without a full-page break.
class FilterFunnelTest < ApplicationSystemTestCase
  test "funnel filters to bookmarked with a label and All restores in one tap" do
    user = users(:keith)
    conversation = conversations(:greeting)
    conversation.bookmark!(user)

    login_as(user)
    visit root_path

    open_funnel
    find("[data-role='filter-show-bookmarked']").click

    assert_selector("[data-role='filter-label']", text: "Bookmarked")
    assert_selector("#conversation_#{conversation.id}")
    assert_no_selector("[data-role='pinned-header']")

    open_funnel
    all_link = find("[data-role='filter-show-all']")
    assert_no_match(/show=/, all_link[:href], "All returns to the unfiltered list in one tap")
    all_link.click

    assert_selector("[data-role='bookmarks-link']")
    assert_no_selector("[data-role='filter-label']")
  end

  test "AE5 empty bookmarked scope suppresses the strip and offers one-tap clear" do
    user = users(:keith)

    login_as(user)
    visit root_path

    open_funnel
    find("[data-role='filter-show-bookmarked']").click

    assert_selector("[data-role='empty-bookmarks']")
    assert_no_selector("[data-role='pinned-header']")
    find("[data-role='filter-clear']").click

    assert_selector("[data-role='bookmarks-link']")
  end

  test "R13 legacy bookmarks entry drives the same funnel state" do
    user = users(:keith)
    conversation = conversations(:greeting)
    conversation.bookmark!(user)

    login_as(user)
    visit root_path

    find("[data-role='bookmarks-link']").click

    assert_selector("#conversation_#{conversation.id}")
    # Wait for the frame swap first: the pre-click button node is detached by the
    # re-render, so reading aria-pressed off it returns the stale value. Re-find after.
    assert_selector("[data-role='filter-label']", text: "Bookmarked")
    button = find("[data-role='filter-button']")
    assert_equal "true", button["aria-pressed"]
    assert_selector("[data-role='filter-announcement']", visible: :all)
  end

  test "R14 scope resets on reload and changes are announced" do
    user = users(:keith)
    conversation = conversations(:greeting)
    conversation.bookmark!(user)

    login_as(user)
    visit root_path

    open_funnel
    find("[data-role='filter-show-bookmarked']").click
    assert_selector("[data-role='filter-label']", text: "Bookmarked")

    page.refresh

    assert_selector("[data-role='bookmarks-link']")
    assert_no_selector("[data-role='filter-label']")
    assert_selector("[data-role='filter-announcement']", visible: :all)
  end

  test "AE7 new unmarked chat appears once under filter without clearing scope" do
    user = users(:keith)
    bookmarked = conversations(:greeting)
    bookmarked.bookmark!(user)
    fresh = user.conversations.create!(assistant: assistants(:samantha), title: "Fresh funnel probe")

    login_as(user)
    visit conversations_path(show: "bookmarked", new_id: fresh.id)

    assert_selector("#conversation_#{fresh.id}")
    assert_selector("[data-role='filter-label']", text: "Bookmarked")

    visit conversations_path(show: "bookmarked")

    assert_no_selector("#conversation_#{fresh.id}")
    assert_selector("#conversation_#{bookmarked.id}")
  end

  test "X beside the filter exits in one tap without opening the menu" do
    user = users(:keith)
    conversation = conversations(:greeting)
    conversation.bookmark!(user)

    login_as(user)
    visit root_path

    assert_no_selector("[data-role='filter-clear-button']")

    open_funnel
    find("[data-role='filter-show-bookmarked']").click
    assert_selector("[data-role='filter-label']", text: "Bookmarked")

    clear = find("[data-role='filter-clear-button']")
    assert_no_match(/show=/, clear[:href], "X must reset Show in one tap")
    clear.click

    assert_selector("[data-role='bookmarks-link']")
    assert_no_selector("[data-role='filter-label']")
    assert_no_selector("[data-role='filter-clear-button']")
  end

  private

  def open_funnel
    find("[data-role='filter-button']").click
    assert_selector("[data-role='filter-menu']")
  end
end

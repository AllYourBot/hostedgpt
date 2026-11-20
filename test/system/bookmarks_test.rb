require "application_system_test_case"

class BookmarksTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    visit root_path
  end

  test "bookmarking a conversation and a message lists them on /bookmarks with a working deep link" do
    # Bookmark a conversation from the sidebar row: hover reveals the row's controls.
    conversation_row = find("#conversation-#{conversations(:greeting).id}")
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

    # The message deep link must actually scroll the bookmarked message into view — not just
    # load the conversation — so shrink the window to force the thread to overflow first.
    page.current_window.resize_to(1400, 500)
    click_element("[data-role='bookmarked-message-link']")
    assert_selector("#message_#{messages(:hear_me).id}")
    scrolled_into_view = false
    diagnostics = ""
    10.times do
      scrolled_into_view, diagnostics = page.evaluate_script(<<~JS)
        (() => {
          const el = document.getElementById("message_#{messages(:hear_me).id}");
          const scroller = document.getElementById("messages");
          if (!el || !scroller) return [false, "missing el or scroller"];
          const box = el.getBoundingClientRect(), view = scroller.getBoundingClientRect();
          return [box.top >= view.top && box.bottom <= view.bottom,
            `url=${window.location.href} scrollTop=${scroller.scrollTop} scrollHeight=${scroller.scrollHeight} clientHeight=${scroller.clientHeight} elTop=${box.top} viewTop=${view.top} viewBottom=${view.bottom}`];
        })()
      JS
      break if scrolled_into_view
      sleep 0.2
    end
    assert scrolled_into_view, "the deep link should scroll the bookmarked message into view (#{diagnostics})"

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

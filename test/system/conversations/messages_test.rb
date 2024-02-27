require "application_system_test_case"

class ConversationMessagesTest < ApplicationSystemTestCase
  setup do
    15.times { |i| users(:keith).conversations.create!(assistant: assistants(:samantha), title: "Conversation #{i+1}") }

    login_as users(:keith)
    @long_conversation = conversations(:greeting)
  end

  test "the conversation auto-scrolls to bottom when page loads" do
    click_text @long_conversation.title
    sleep 0.2
    assert_hidden "#scroll-button", "Page should have auto-scrolled to the bottom and hidden the scroll button."
    assert_at_bottom
  end

  test "the scroll appears and disappears based on scroll position" do
    click_text @long_conversation.title
    sleep 0.2

    scroll_to find_messages.second
    assert_visible "#scroll-button", wait: 0.01

    scroll_to find_messages.first
    assert_visible "#scroll-button", wait: 0.2

    assert_scrolled_to_bottom do
      scroll_to find_messages.last
      assert_hidden "#scroll-button", wait: 0.2
    end
  end

  test "clicking scroll down button scrolls the page to the bottom" do
    click_text @long_conversation.title
    sleep 0.2

    scroll_to find_messages.first
    assert_visible "#scroll-button", wait: 0.5

    assert_scrolled_to_bottom do
      click_element "#scroll-button button"
      assert_hidden "#scroll-button", wait: 1
    end
  end

  test "submitting a message with ENTER inserts a new message with morphing & scrolls down" do
    visit conversation_messages_path(@long_conversation.id)
    scroll_to_bottom "#right-content"

    # TODO: instead of these 2 lines if we do "click_text @long_conversation.title" the test fails. There is a bug
    # and the page won't morph after a click with turbo-action="advance". We need to fix this bug within Turbo.

    assert_page_morphed do
      send_keys "Watch me appear"
      send_keys "enter"
      sleep 0.5
    end

    assert find_messages.last.text.include?("Watch me appear"), "The last message should have contained the submitted text"
  end

  test "when the AI replies with a message it appears with morphing and scrolls down" do
    click_text @long_conversation.title
    sleep 0.5
    new_message = nil

    assert_page_morphed do
      new_message = @long_conversation.messages.create! assistant: @long_conversation.assistant, content_text: "Stub: ", role: :user
      sleep 0.5
      assert find_messages.last.text.include?("Stub:"), "The last message should have contained the submitted text"
    end

    assert_page_morphed do
      new_message.content_text = "The quick brown fox jumped over the lazy dog and this line needs to wrap to scroll." +
                                  "But it was not long enough so I'm adding more text on this second line to ensure it."
      GetNextAIMessageJob.broadcast_updated_message(new_message)
      sleep 0.5
      assert find_messages.last.text.include?("The quick brown"), "The last message should have contained the submitted text"
    end

    new_message.save!
  end

  test "clicking new compose icon in the top-right starts a new conversation and preserves sidebar scroll" do
    click_text @long_conversation.title

    assert_did_not_scroll("#left-column") do
      assert_selector "#conversation a[data-role='pencil']"
      assert_shows_tooltip "#conversation a[data-role='pencil']", "New chat"

      click_element "#conversation a[data-role='pencil']"
      assert_current_path new_assistant_message_path(@long_conversation.assistant)
    end
  end

  test "when conversation is scrolled to the bottom, when the browser resizes it auto-scrolls to stay at the bottom" do
    click_text @long_conversation.title

    assert_stays_at_bottom do
      resize_browser_to(1400, 700)
    end
  end

  test "when conversation is NOT scrolled to the bottom, when the browser resizes it DOES NOT auto-scroll so what scrolled to stays visible" do
    click_text @long_conversation.title
    sleep 0.2
    scroll_to find_messages.second

    assert_did_not_scroll do
      resize_browser_to(1400, 700)
    end
  end

  private

  def find_conversations
    all("#conversations [data-role='conversation']").to_a
  end

  def watch_page_for_morphing
    # Within automated system tests, it's difficult to know if a page morphed or not. When a page does morph
    # it should only replace the DOM elements which changed. This has the side effect of preserving scroll position.
    # However, full page Turbo transitions also have other hacks in place to preserve scroll position so that
    # is not enough. The best solution I found was to test for the scroll position *and* to test if a couple
    # elements we expect NOT to be replaced stay put. The way I test this is by "tagging" an element; this adds an
    # attribute to the element which morphdom ignores so it does not recognize this as a changed element. A full
    # page body replacement or a turbo-frame replacement does not re-add these attributes, so if the tag is no longer
    # present then we know morphing did not occur.
    tag("#left-column")
    tag(find_messages.first)
    @left_scroll_position = get_scroll_position("#left-column")
    sleep 1 # this delay is so long b/c we wait 0.5s before scrolling the page down
    @body_scroll_position = get_scroll_position("#right-content")
    assert_not_equal 0, @body_scroll_position, "The page should be scrolled down before acting on it"
  end

  def tag(selector_or_element)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element)
    end

    page.execute_script("arguments[0]._morphMonitor = true", element)
  end

  def assert_page_morphed
    raise "No block given" unless block_given?
    watch_page_for_morphing

    yield

    sleep 1 # this delay is so long b/c we wait 0.5s before scrolling the page down
    assert get_scroll_position("#right-content") > @body_scroll_position, "The page should have scrolled down further"
    assert_hidden "#scroll-button", "The page did not scroll all the way down"
    assert tagged?("#left-column"), "The page did not morph; a tagged element got replaced."
    assert tagged?(find_messages.first), "The page did not morph; a tagged element got replaced."
    assert_equal @left_scroll_position, get_scroll_position("#left-column"), "The left column lost it's scroll position"
  end

  def tagged?(selector_or_element)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element)
    end

    element[:'_morphMonitor']
  end
end

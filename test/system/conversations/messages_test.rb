require "application_system_test_case"

class ConversationMessagesTest < ApplicationSystemTestCase
  setup do
    15.times { |i| users(:keith).conversations.create!(assistant: assistants(:samantha), title: "Conversation #{i+1}") }

    login_as users(:keith)
    @long_conversation = conversations(:greeting)
  end

  test "the conversation auto-scrolls to bottom when page loads" do
    click_text @long_conversation.title

    assert_hidden "#scroll-button", "Page should have auto-scrolled to the bottom and hidden the scroll button."
  end

  test "the scroll appears and disappears based on scroll position" do
    click_text @long_conversation.title

    scroll_to find_messages.second
    assert_visible "#scroll-button", wait: 0.2

    scroll_to find_messages.first
    assert_visible "#scroll-button", wait: 0.2

    scroll_to find_messages.last
    assert_hidden "#scroll-button", wait: 0.2
  end

  test "clicking scroll down button scrolls the page to the bottom" do
    click_text @long_conversation.title

    scroll_to find_messages.first
    assert_visible "#scroll-button", wait: 0.5
    scroll_position = get_scroll_position("#right-content")

    click_element "#scroll-button button"
    assert_hidden "#scroll-button", wait: 1
    assert_not_equal scroll_position, get_scroll_position("#right-content")
  end

  test "submitting a message with ENTER inserts a new message with morphing & scrolls down" do
    visit conversation_messages_path(@long_conversation.id)
    scroll_to find_conversations.last
    sleep 0.5
    # Note: instead of these 3 lines if we do "click_text @long_conversation.title" the test fails. There is a bug
    # and the page won't morph after a click with turbo-action="advance"

    watch_page_for_morphing

    send_keys "Watch me appear"
    send_keys "enter"
    sleep 0.5

    assert_page_morphed
    assert find_messages.last.text.include?("Watch me appear"), "The last message should have contained the submitted text"
  end

  test "when the AI replies with a message it appears with morphing and scrolls down" do
    click_text @long_conversation.title
    sleep 0.5

    watch_page_for_morphing

    @long_conversation.messages.create! assistant: @long_conversation.assistant, content_text: "Watch me appear", role: :user
    sleep 0.5

    assert_page_morphed
    assert find_messages.last.text.include?("Watch me appear"), "The last message should have contained the submitted text"
  end

  test "clicking new compose icon in the top-right starts a new conversation and preserves sidebar scroll" do
    click_text @long_conversation.title

    left_scroll_position = get_scroll_position("#left-column")

    assert_selector "#conversation a[data-role='pencil']"
    assert_shows_tooltip "#conversation a[data-role='pencil']", "New chat"

    click_element "#conversation a[data-role='pencil']"
    assert_current_path new_assistant_message_path(@long_conversation.assistant)
    assert_equal left_scroll_position, get_scroll_position("#left-column")
  end

  private

  def find_messages
    all("#conversation [data-role='message']").to_a
  end

  def find_conversations
    all("#conversations [data-role='conversation']").to_a
  end

  def get_scroll_position(selector)
    page.evaluate_script("arguments[0].scrollTop", find(selector))
  end

  def watch_page_for_morphing
    tag("#left-column")
    tag(find_messages.first)
    @left_scroll_position = get_scroll_position("#left-column")
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

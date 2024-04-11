require "application_system_test_case"

class ConversationMessagesTest < ApplicationSystemTestCase
  setup do
    15.times { |i| users(:keith).conversations.create!(assistant: assistants(:samantha), title: "Conversation #{i+1}") }

    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    @new_message = @conversation.messages.create! assistant: @conversation.assistant, content_text: "Stub: ", role: :assistant

    visit conversation_messages_path(@conversation.id)
  end

  test "clipboard icon shows tooltip" do
    msg = hover_last_message
    assert_shows_tooltip msg.find_role("clipboard"), "Copy"
  end

  test "clicking clipboard icon changes the tooltip & icon to check, mousing out changes it back" do
    msg = hover_last_message
    clipboard = msg.find_role("clipboard")

    clipboard.click
    assert_shows_tooltip clipboard, "Copied!"

    msg.find_role("regenerate").hover
    assert_shows_tooltip clipboard, "Copy"
  end

  test "regenerate icon shows tooltip" do
    msg = hover_last_message
    assert_shows_tooltip msg.find_role("regenerate"), "Regenerate"
  end

  test "clicking regenerate icon shows menu and triggers re-generation" do
    existing_assistant = @conversation.assistant
    new_assistant = @user.assistants.ordered.where.not(id: existing_assistant.id).first

    msg = hover_last_message
    regenerate = msg.find_role("regenerate")

    regenerate.click
    assert_text "Using #{existing_assistant.name}"
    assert_text "Using #{new_assistant.name}"

    assert_equal existing_assistant.name, last_message.find_role("from").text

    click_text "Using #{new_assistant.name}"
    sleep 1
    assert_equal new_assistant.name, last_message.find_role("from").text
  end

  test "submitting a message with ENTER inserts two new messages with morphing" do
    assert_page_morphed do
      send_keys "Watch me appear"
      send_keys "enter"

      assert_true "The last user message should have contained the submitted text" do
        len = find_messages.length
        find_messages[len-2].text.include?("Watch me appear")
      end
    end
  end

  test "when the AI replies with a message it appears with morphing" do
    assert last_message.text.include?("Stub:"), "The last message should have contained the submitted text"

    assert_page_morphed do
      @new_message.content_text = "The quick brown fox jumped over the lazy dog and this line needs to wrap to scroll." +
                                  "But it was not long enough so I'm adding more text on this second line to ensure it."
      GetNextAIMessageJob.broadcast_updated_message(@new_message)
      assert_true "The last message should have contained the submitted text but it contains '#{last_message.text}'" do
        last_message.text.include?("The quick brown")
      end
      @new_message.save!
    end
  end

  private

  def hover_last_message
    msg = last_message
    msg.hover
    msg
  end

  def assert_page_morphed
    raise "No block given" unless block_given?
    watch_page_for_morphing

    yield

    sleep 1 # this delay is so long b/c we wait 0.5s before scrolling the page down
    assert get_scroll_position("section #messages") > @messages_scroll_position, "The page should have scrolled down further"
    assert_hidden "#scroll-button", "The page did not scroll all the way down"
    assert tagged?("nav"), "The page did not morph; a tagged element got replaced."
    assert tagged?(first_message), "The page did not morph; a tagged element got replaced."
    assert_equal @nav_scroll_position, get_scroll_position("nav"), "The left column lost it's scroll position"
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
    tag("nav")
    tag(first_message)
    @nav_scroll_position = get_scroll_position("nav")
    sleep 1 # this delay is so long b/c we wait 0.5s before scrolling the page down
    @messages_scroll_position = get_scroll_position("section #messages")
    assert_not_equal 0, @messages_scroll_position, "The page should be scrolled down before acting on it"
  end

  def tag(selector_or_element)
    element = if selector_or_element.is_a?(Capybara::Node::Element)
      selector_or_element
    else
      find(selector_or_element)
    end

    page.execute_script("arguments[0]._morphMonitor = true", element)
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

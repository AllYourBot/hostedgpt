require "application_system_test_case"
include ActionView::RecordIdentifier

class ConversationMessagesPlaybackTest < ApplicationSystemTestCase
  include MorphingHelper

  setup do
    login_as users(:keith)
    @conversation = conversations(:hello_claude)
    # Oddly, visit_and_scroll_wait in here causes tests to fail when running in parallel
  end

  test "sentence controller values do not revert when the page morphs" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    page.execute_script("arguments[0].setAttribute('data-playback-sentences-index-value', '123')", second_assistant_message.native)

    assert_page_morphed do
      @conversation.messages.create!(role: :assistant, assistant: @conversation.assistant, content_text: "Hello, world!")
      @conversation.broadcast_refresh
    end

    assert_equal "123", second_assistant_message["data-playback-sentences-index-value"], "The playback sentence value should not have changed"
  end

  test "when page loads a play buttons are visible, click play changes it to stop, audio plays, and it reverts when audo is completed and it can be clicked again" do
    visit_and_scroll_wait conversation_messages_path(@conversation)

    first_assistant_message.hover
    first_play = first_assistant_message.find_role("play")
    assert first_play.visible?

    second_assistant_message.hover
    second_play = second_assistant_message.find_role("play")
    assert second_play.visible?

    second_play.click
    refute second_play.visible?
    assert second_assistant_message.find_role("stop").visible?, "Play should have changed to stop upon click"

    first_assistant_message.hover
    assert first_play.visible?, "The play button that was NOT clicked should not have changed"

    second_assistant_message.hover
    assert_true "Play button should have reappeared at the end of playback" do
      second_play.visible?
    end

    # Try playing a second time
    second_play.click
    refute second_play.visible?
    assert second_assistant_message.find_role("stop").visible?, "Play should have changed to stop upon click"

    assert_true "Play button should have reappeared at the end of playback" do
      second_play.visible?
    end
  end

  test "playback controller does not reconnect when another chunk of message streams" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    inner_message_that_will_get_replaced = second_assistant_message.find_role("inner-message")
    tag second_assistant_message
    tag inner_message_that_will_get_replaced
    msg = @conversation.latest_message_for_version(1)
    msg.content_text += "The quick brown fox jumped over the lazy dog."

    assert_equal second_assistant_message[:id], dom_id(msg)
    GetNextAIMessageJob.broadcast_updated_message(msg)

    assert_true "The last message should have streamed an update" do
      second_assistant_message.text.include?("The quick brown")
    end

    assert tagged?(second_assistant_message)
    refute tagged?(inner_message_that_will_get_replaced)
  end

  test "when stop button is pressed it stops playback" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    second_assistant_message.hover
    play = second_assistant_message.find_role("play")
    stop = second_assistant_message.find_role("stop")
    assert play.visible?
    refute stop.visible?

    play.click
    refute play.visible?
    assert stop.visible?

    stop.click
    assert play.visible?, "Clicking stop should have flipped it back to play"
    refute stop.visible?
  end

  private

  def first_assistant_message
    find_messages.second
  end

  def second_assistant_message
    find_messages.fourth
  end
end

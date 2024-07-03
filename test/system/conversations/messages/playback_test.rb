require "application_system_test_case"

class ConversationMessagesPlaybackTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    @conversation = conversations(:hello_claude)
  end

  test "ensure no auto playback on a normal load" do
    visit_and_scroll_wait conversation_messages_path(@conversation, version: 1)

    speaker = page.find("[data-controller~='speaker']")
    refute speaker["data-speaker-playback-index-value"], "initial index should not be present"

    messages = page.all("[data-role='assistant-message']")
    assert_equal 2, messages.length

    assert_equal "1",     messages[0]["data-playback-index-value"]
    assert_equal "0",     messages[0]["data-playback-sentences-index-value"]
    assert_equal "false", messages[0]["data-playback-speaker-active-value"]

    assert_equal "3",     messages[1]["data-playback-index-value"]
    assert_equal "0",     messages[1]["data-playback-sentences-index-value"]
    assert_equal "false", messages[1]["data-playback-speaker-active-value"]
  end

  test "ensure playback index & auto-speaker index stay in sync" do
    visit_and_scroll_wait conversation_messages_path(@conversation, version: 1, last_message_playback_active: true)
    speaker = page.find("[data-controller~='speaker']")
    messages = page.all("[data-role='assistant-message']")
    assert_equal 2, messages.length

    assert_equal "3", speaker["data-speaker-playback-index-value"], "initial index should have been set"

    assert_equal "1",     messages[0]["data-playback-index-value"]
    assert_equal "0",     messages[0]["data-playback-sentences-index-value"]
    assert_equal "false", messages[0]["data-playback-speaker-active-value"]

    assert_equal "3",     messages[1]["data-playback-index-value"]
    assert_equal "0",     messages[1]["data-playback-sentences-index-value"]
    assert_equal "true",  messages[1]["data-playback-speaker-active-value"]

    # Setting a message to speaker-active propogates
    page.execute_script("document.querySelectorAll(`[data-role='assistant-message']`)[0].setAttribute('data-playback-speaker-active-value', 'true')")

    assert_equal "1", speaker["data-speaker-playback-index-value"]
    assert_equal "true", messages[0]["data-playback-speaker-active-value"]
    assert_equal "false",  messages[1]["data-playback-speaker-active-value"]

    # Changing the speaker index propogates
    page.execute_script("document.querySelector(`[data-controller~='speaker']`).setAttribute('data-speaker-playback-index-value', '3')")

    assert_equal "3", speaker["data-speaker-playback-index-value"]
    assert_equal "false", messages[0]["data-playback-speaker-active-value"]
    assert_equal "true",  messages[1]["data-playback-speaker-active-value"]

    # Stop all speaker auto playback
    page.execute_script("Stimulus.getControllerForElementAndIdentifier(document.querySelector(`[data-controller~='speaker']`), 'speaker').stop()")

    refute speaker["data-speaker-playback-index-value"]
    assert_equal "false", messages[0]["data-playback-speaker-active-value"]
    assert_equal "false",  messages[1]["data-playback-speaker-active-value"]
  end
end

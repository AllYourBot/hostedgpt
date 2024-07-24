require "application_system_test_case"

class ConversationMessagesPlaybackTest < ApplicationSystemTestCase
  include MicrophoneHelper
  include MorphingHelper

  setup do
    login_as users(:keith)
    @conversation = conversations(:hello_claude)
  end

  test "press play on a new conversation, ask a question which loads a new page, the answer plays back after a delayed stream, and again for a second question" do
    stub_features(voice: true) do
      visit new_assistant_message_path(assistants(:samantha))
      enable_mic.click
      disable_mic.visible?

      user_speaks "You there?"

      assert_current_path newly_created_conversation_path
      disable_mic.visible?

      assert_spoke_to_sentence "0", assistant_messages.last
      assert_finished_speaking nil

      stream_ai_reply "Yes, I'm here. Are you there?", thinking: true

      assert_spoke_to_sentence "1", assistant_messages.last
      assert_finished_speaking nil

      stream_ai_reply "Yes, I'm here. Are you there?", thinking: false

      assert_spoke_to_sentence "2", assistant_messages.last
      assert_finished_speaking Message.last

      user_speaks "Yes"
      stream_ai_reply "That's great."

      assert_spoke_to_sentence "1", assistant_messages.last
      assert_finished_speaking Message.last
    end
  end

  test "loading an existing conversation, pressing play does not play anything, but then asking a question causes just that answer to play back" do
    stub_features(voice: true) do
      visit conversation_messages_path(@conversation)

      enable_mic.click
      disable_mic.visible?

      # Nothing should play:
      assert_finished_speaking @conversation.latest_message_for_version
      assert_spoke_to_sentence "0", assistant_messages.first
      assert_spoke_to_sentence "0", assistant_messages.last

      user_speaks "You there?"
      stream_ai_reply "Yes, I'm here. Are you there?"

      assert_finished_speaking Message.last
      assert_spoke_to_sentence "2", assistant_messages.last

      user_speaks "Yes"
      stream_ai_reply "That's great."

      assert_finished_speaking Message.last
      assert_spoke_to_sentence "1", assistant_messages.last
    end
  end

  test "speaker values do not clear on page morph" do
  end

  private

  def assistant_messages
    page.all("[data-subrole='assistant-message']")
  end

  def speaker
    page.find("[data-controller~='speaker']")
  end

  def user_speaks(text)
    audio_finishes_processing do
      page.execute_script("Listener.$.consideration = `#{text}`")
    end
  end

  def newly_created_conversation_path
    conversation_messages_path(Conversation.last.id+1, version: 1)
  end

  def stream_ai_reply(text, thinking: false)
    msg = Message.last
    msg.content_text = text
    GetNextAIMessageJob.broadcast_updated_message(msg, thinking: thinking)
    if !thinking
      msg.save!
      msg.conversation.broadcast_refresh
    end
    nil
  end

  def assert_spoke_to_sentence(expected, element)
    assert_true "sentence index value did not update to #{expected}" do
      expected == element["data-playback-sentences-index-value"]
    end
    true
  end

  def assert_finished_speaking(msg)
    if msg == nil
      assert_nil speaker["data-speaker-playedback-id-value"]
    else
      assert_true "speaker playback did not update to #{msg.id}" do
        msg.id == speaker["data-speaker-playedback-id-value"].to_i
      end
    end
    true
  end

  def audio_finishes_processing(&block)
    assistant_message_length = assistant_messages.length
    assert_page_morphed do
      yield
    end

    assert_true do
      assistant_messages.length > assistant_message_length
    end
    true
  end
end

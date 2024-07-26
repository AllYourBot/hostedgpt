require "application_system_test_case"

class ConversationMessagesPlaybackTest < ApplicationSystemTestCase
  include MicrophoneHelper
  include NavigationHelper

  setup do
    login_as users(:keith)
    @conversation = conversations(:hello_claude)
  end

  test "speaker controller values do not revert when the page morphs" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    page.execute_script("arguments[0].setAttribute('data-speaker-playedback-id-value', '123')", assistant_messages[1].native)
    page.execute_script("arguments[0].setAttribute('data-speaker-waiting-for-next-playback-value', 'true')", assistant_messages[1].native)

    assert_page_morphed do
      @conversation.messages.create!(role: :assistant, assistant: @conversation.assistant, content_text: "Hello, world!")
      @conversation.broadcast_refresh
    end

    assert_equal "123", assistant_messages[1]["data-speaker-playedback-id-value"], "The speaker playedback value should not have changed"
    assert_equal "true", assistant_messages[1]["data-speaker-waiting-for-next-playback-value"], "The speaker waiting value should not have changed"
  end

  # test "when we are speaking a conversation, the answer plays back after a MORPH rather than a stream" do
  #   visit conversation_messages_path(@conversation)

  #   enable_mic.click
  # end

  test "press play on a new conversation, ask a question which loads a new page, the answer plays back after a STREAM, and again for a second question that MORPHS" do
    stub_features(voice: true) do
      visit new_assistant_message_path(assistants(:samantha))
      enable_mic.click
      disable_mic.visible?

      user_speaks "You there?"

      disable_mic.visible? # checking again because page changed

      assert_spoke_to_sentence "0", assistant_messages.last
      assert_finished_speaking nil

      stream_ai_reply "Yes, I'm here. Are you there?", thinking: true

      assert_spoke_to_sentence "1", assistant_messages.last
      assert_finished_speaking nil

      stream_ai_reply "Yes, I'm here. Are you there?", thinking: false

      assert_spoke_to_sentence "2", assistant_messages.last
      assert_finished_speaking Message.last

      user_speaks "Yes"
      morph_ai_reply "That's great."

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

  test "while speaking a long reply if you click stop it stops speaking right away even though more streams in, and when re-enabled it does not play the existing message." do
    stub_features(voice: true) do
      visit conversation_messages_path(@conversation)

      enable_mic.click

      previous_msg = @conversation.latest_message_for_version

      user_speaks "Write me a poem."
      stream_ai_reply "This is the first sentence of a long reply. The quick brown fox jumped over the lazy dog. ", thinking: true

      assert_spoke_to_sentence "1", assistant_messages[2]
      assert_finished_speaking previous_msg

      disable_mic.click

      stream_ai_reply "This is the first sentence of a long reply. The quick brown fox jumped over the lazy dog. A final sentence."

      assert_finished_speaking @conversation.latest_message_for_version
      assert_spoke_to_sentence "1", assistant_messages[2]

      enable_mic.click

      assert_finished_speaking @conversation.latest_message_for_version
      assert_spoke_to_sentence "1", assistant_messages[2]

      user_speaks "You there?"
      stream_ai_reply "Yes, I'm here. Are you there?"

      assert_finished_speaking Message.last
      assert_spoke_to_sentence "2", assistant_messages[3]
      assert_spoke_to_sentence "1", assistant_messages[2] # double-check that previous message did not speak any more
    end
  end

  test "while speaking a long reply if you click stop it stops speaking right away even though more was queued up" do
    # This is hard to test because the abort actually happens deep within audioService when the aborting "pip" sound
    # is played. The speaker's data-playback-sentences-index-value will reflect all the sentences and
    # data-speaker-playedback-id-value will be set to this message even before they mp3 files have fully finished.
  end

  test "if a second assistant reply comes AFTER finishing the first one, the second reply auto-plays" do
    stub_features(voice: true) do
      visit conversation_messages_path(@conversation)

      enable_mic.click

      user_speaks "What is the weather in Austin?"
      stream_ai_reply "One second. I'm checking the weather."

      assert_finished_speaking Message.last
      assert_spoke_to_sentence "2", assistant_messages[2]

      assert_difference "Message.count", 1 do
        stub_new_ai_reply
        stream_ai_reply "The weather is sunny with a high of 100 degrees."
      end

      assert_finished_speaking Message.last
      assert_spoke_to_sentence "1", assistant_messages[3]
    end
  end

  test "if a second assistant reply comes DURING speaking the first one, the first still finishes and then the second auto plays" do
      stub_features(voice: true) do
      visit conversation_messages_path(@conversation)

      enable_mic.click
      old_msg = @conversation.latest_message_for_version

      user_speaks "What is the weather in Austin?"
      stream_ai_reply "One second. I'm checking the weather.", thinking: true
      first_reply = Message.last

      assert_finished_speaking old_msg
      assert_spoke_to_sentence "1", assistant_messages[2]

      second_reply = nil
      assert_difference "Message.count", 1 do
        stub_new_ai_reply
        second_reply = Message.last
        stream_ai_reply "The weather is sunny with a high of 100 degrees.", message: second_reply
      end

      assert_true "new assistant message did not appear on the screen" do
        assistant_messages.length == 4
      end
      assert_spoke_to_sentence "0", assistant_messages[3] # new msg should not start yet

      stream_ai_reply "One second. I'm checking the weather.", message: first_reply
      assert_spoke_to_sentence "2", assistant_messages[2]

      assert_finished_speaking second_reply
      assert_spoke_to_sentence "1", assistant_messages[3]
    end
  end

  test "if an assistant reply turns into a tool call (which hides the message), when the final assistant reply comes it auto plays" do
    stub_features(voice: true) do
      visit conversation_messages_path(@conversation)

      enable_mic.click

      user_speaks "What is the weather in Austin?"
      stream_ai_reply ""
      first_reply = Message.last
      assistant_message_count = assistant_messages.length

      first_reply.update!(content_tool_calls: [{ type: "function" }])
      assert first_reply.only_tool_response?
      first_reply.conversation.broadcast_refresh

      assert_true "assistant message should have disappeared from screen" do
        assistant_messages.length == assistant_message_count - 1
      end

      second_reply = nil
      assert_difference "Message.count", 1 do
        stub_new_ai_reply
        second_reply = Message.last
        stream_ai_reply "I've checked the weather and it's sunny today.", message: second_reply
      end

      assert_true "a new assistant message should have appeared on screen" do
        assistant_messages.length == assistant_message_count
      end

      assert_finished_speaking Message.last
      assert_spoke_to_sentence "1", assistant_messages[2]
    end
  end

  # TODO: What about clicking play button while speaking is engaged. Should this be supported, or should
  # the play buttons be hidden, or should clicking play disable speaking?
  #
  # test "can click play on any previous message during speaking and speaking will continue to work" do
  # end

  private

  def assistant_messages
    page.all("[data-subrole='assistant-message']")
  end

  def speaker
    page.find("[data-controller~='speaker']")
  end

  def user_speaks(text)
    if current_path.include?("/conversation")
      audio_finishes_processing do
        page.execute_script("Listener.$.consideration = `#{text}`")
      end
    else
      page.execute_script("Listener.$.consideration = `#{text}`")
      assert_true "current_path did not change" do
        current_path.include?("/conversation")
      end
    end
  end

  def stub_new_ai_reply
    msg = @conversation.latest_message_for_version
    @conversation.messages.create!(
      assistant: @conversation.assistant,
      role: :assistant,
      content_text: nil,
      version: msg.version,
      index: msg.index + 1,
    )
  end

  def stream_ai_reply(text, message: nil, thinking: false)
    msg = message || Message.last
    msg.content_text = text
    GetNextAIMessageJob.broadcast_updated_message(msg, thinking: thinking)
    if !thinking
      msg.save!
      msg.conversation.broadcast_refresh
    end
    nil
  end

  def morph_ai_reply(text, message: nil)
    msg = message || Message.last
    msg.content_text = text
    msg.save!
    msg.conversation.broadcast_refresh
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

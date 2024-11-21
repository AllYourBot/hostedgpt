require "test_helper"

class AIBackend::AnthropicTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:hello_claude)
    @assistant = assistants(:keith_claude35)
    @assistant.language_model.update!(supports_tools: false) # this will change the TestClient response so we want to be selective about this
    @anthropic = AIBackend::Anthropic.new(
      users(:keith),
      @assistant,
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    TestClient::Anthropic.new(access_token: "abc")
  end

  test "initializing client works" do
    assert @anthropic.client.present?
  end

  test "stream_next_conversation_message works to stream text and uses model from assistant" do
    assert_not_equal @assistant, @conversation.assistant, "Should force this next message to use a different assistant so these don't match"

    TestClient::Anthropic.stub :text, nil do # this forces it to fall back to default text
      streamed_text = ""
      @anthropic.stream_next_conversation_message { |chunk| streamed_text += chunk }
      expected_start = "Hello this is model claude-3-5-sonnet-20240620 with instruction \"Note these additional items that you've been told and remembered:\\n\\nHe lives in Austin, Texas\\n\\nHe owns a cat\\n\\nFor the user, the current time"
      expected_end = "\"! How can I assist you today?"
      assert streamed_text.start_with?(expected_start)
      assert streamed_text.end_with?(expected_end)
    end
  end

  test "preceding_conversation_messages constructs a proper response and pivots on images" do
    preceding_conversation_messages = @anthropic.send(:preceding_conversation_messages)

    assert_equal @conversation.messages.length-1, preceding_conversation_messages.length

    @conversation.messages.ordered.each_with_index do |message, i|
      next if @conversation.messages.length == i+1

      if message.documents.present?
        assert_instance_of Array, preceding_conversation_messages[i][:content]
        assert_equal message.documents.length+1, preceding_conversation_messages[i][:content].length
      else
        assert_equal preceding_conversation_messages[i][:content], message.content_text
      end
    end
  end

  # TODO
  # test "preceding_conversation_messages only considers messages on the intended conversation version and includes the correct names" do
  # end

  # TODO
  # test "preceding_conversation_messages includes the appropriate tool details" do
  # end
end

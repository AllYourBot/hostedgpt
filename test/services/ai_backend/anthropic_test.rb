require "test_helper"

class AIBackend::AnthropicTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:attachments)
    @anthropic = AIBackend::Anthropic.new(users(:keith),
      assistants(:keith_claude3),
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    @test_client = TestClient::Anthropic.new(access_token: 'abc')
  end

  test "initializing client works" do
    assert @anthropic.client.present?
  end

  test "get_next_chat_message works" do
    assert_equal "https://api.anthropic.com/", @anthropic.client.uri_base
    streamed_text = @test_client.messages(model: "claude_3_opus_20240229", system: "You are a helpful assistant")

    assert_equal "Hello this is model claude_3_opus_20240229 with instruction \"You are a helpful assistant\"! How can I assist you today?", streamed_text
  end

  test "get_next_chat_message works with APIService" do
    anthropic = AIBackend::Anthropic.new(users(:taylor),
      assistants(:alpaca_asst),
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    assert_equal "http://taylor.org/doit", anthropic.client.uri_base
    assert_equal "Hello this is model alpaca:medium with instruction \"Take 5 then 4\"! How can I assist you today?", anthropic.get_next_chat_message
  end

  test "preceding_messages constructs a proper response and pivots on images" do
    preceding_messages = @anthropic.send(:preceding_messages)

    assert_equal @conversation.messages.length-1, preceding_messages.length

    @conversation.messages.ordered.each_with_index do |message, i|
      next if @conversation.messages.length == i+1

      if message.documents.present?
        assert_instance_of Array, preceding_messages[i][:content]
        assert_equal message.documents.length+1, preceding_messages[i][:content].length
      else
        assert_equal preceding_messages[i][:content], message.content_text
      end
    end
  end

  test "preceding_messages only considers messages up to the assistant message being generated" do
    @anthropic = AIBackend::Anthropic.new(users(:keith), assistants(:samantha), @conversation, messages(:yes_i_can))

    preceding_messages = @anthropic.send(:preceding_messages)

    assert_equal 1, preceding_messages.length
    assert_equal preceding_messages[0][:content], messages(:can_you_hear).content_text
  end
end

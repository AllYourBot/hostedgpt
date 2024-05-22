require "test_helper"

module AIBackends
  class AnthropicTest < ActiveSupport::TestCase
    setup do
      @conversation = conversations(:attachments)
      @anthropic = Anthropic.new(users(:keith),
        assistants(:samantha),
        @conversation,
        @conversation.latest_message_for_version(:latest)
      )
      @test_client = TestClients::Anthropic.new(access_token: 'abc')
    end

    test "initializing client works" do
      assert @anthropic.client.present?
    end

    test "get_next_chat_message works" do
      assert_equal @test_client.messages(model: "gpt-4", system: "You are a helpful assistant"), @anthropic.get_next_chat_message
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
      @anthropic = Anthropic.new(users(:keith), assistants(:samantha), @conversation, messages(:yes_i_can))

      preceding_messages = @anthropic.send(:preceding_messages)

      assert_equal 1, preceding_messages.length
      assert_equal preceding_messages[0][:content], messages(:can_you_hear).content_text
    end
  end
end

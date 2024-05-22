require "test_helper"

module AIBackends
  class OpenAITest < ActiveSupport::TestCase
    setup do
      @conversation = conversations(:attachments)
      @openai = OpenAI.new(
        users(:keith),
        assistants(:samantha),
        @conversation,
        @conversation.latest_message_for_version(:latest)
      )
      @test_client = TestClients::OpenAI.new(access_token: 'abc')
    end

    test "uses model from assistant" do
      openai = OpenAI.new(
        users(:keith),
        assistants(:keith_claude3),
        @conversation,
        @conversation.latest_message_for_version(:latest)
      )
      assert_equal "Hello this is model claude-3-opus-20240229 with instruction nil! How can I assist you today?", openai.get_next_chat_message
    end

    test "initializing client works" do
      assert @openai.client.present?
    end

    test "get_next_chat_message works" do
      assert_equal "Hello this is model gpt-4 with instruction \"You are a helpful assistant\"! How can I assist you today?", @openai.get_next_chat_message
    end

    test "preceding_messages constructs a proper response and pivots on images" do
      preceding_messages = @openai.send(:preceding_messages)

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
      @openai = OpenAI.new(users(:keith), assistants(:samantha), @conversation, messages(:yes_i_can))

      preceding_messages = @openai.send(:preceding_messages)

      assert_equal 1, preceding_messages.length
      assert_equal preceding_messages[0][:content], messages(:can_you_hear).content_text
    end
  end
end

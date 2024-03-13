require "test_helper"

module AIBackends
  class AnthropicTest < ActiveSupport::TestCase
    setup do
      @conversation = conversations(:attachments)
      @anthropic = Anthropic.new(users(:keith), assistants(:samantha), @conversation, @conversation.latest_message)
      @test_client = TestClients::Anthropic.new(access_token: 'abc')
    end

    test "initializing client works" do
      assert @anthropic.client.present?
    end

    test "get_next_chat_message works" do
      assert_equal @test_client.messages, @anthropic.get_next_chat_message
    end

    test "existing_messages constructs a proper response and pivots on images" do
      existing_messages = @anthropic.send(:existing_messages)

      assert_equal @conversation.messages.length-1, existing_messages.length

      @conversation.messages.ordered.each_with_index do |message, i|
        next if @conversation.messages.length == i+1

        if message.documents.present?
          assert_instance_of Array, existing_messages[i][:content]
          assert_equal message.documents.length+1, existing_messages[i][:content].length
        else
          assert_equal existing_messages[i][:content], message.content_text
        end
      end
    end

    test "existing_messages only considers messages up to the assistant message being generated" do
      @anthropic = Anthropic.new(users(:keith), assistants(:samantha), @conversation, messages(:yes_i_can))

      existing_messages = @anthropic.send(:existing_messages)

      assert_equal 1, existing_messages.length
      assert_equal existing_messages[0][:content], messages(:can_you_hear).content_text
    end
  end
end
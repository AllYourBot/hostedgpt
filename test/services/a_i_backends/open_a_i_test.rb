require "test_helper"

module AIBackends
  class OpenAITest < ActiveSupport::TestCase
    setup do
      @conversation = conversations(:attachments)
      @openai = OpenAI.new(users(:keith), assistants(:samantha), @conversation)
      @test_client = TestClients::OpenAI.new(access_token: 'abc')
    end

    test "initializing client works" do
      assert @openai.client.present?
    end

    test "get_next_chat_message works" do
      assert_equal @test_client.chat, @openai.get_next_chat_message
    end

    test "existing_messages constructs a proper response and pivots on images" do
      existing_messages = @openai.send(:existing_messages)

      assert_equal @conversation.messages.length, existing_messages.length

      @conversation.messages.sorted.each_with_index do |message, i|
        if message.documents.present?
          assert_instance_of Array, existing_messages[i][:content]
          assert_equal message.documents.length+1, existing_messages[i][:content].length
        else
          assert_equal existing_messages[i][:content], message.content_text
        end
      end
    end
  end
end
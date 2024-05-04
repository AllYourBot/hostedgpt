require "test_helper"

class GetNextAIMessageJobOpenaiTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:greeting)
    @user = @conversation.user
    @conversation.messages.create! role: :user, content_text: "Are you still there?", assistant: @conversation.assistant
    @message = @conversation.latest_message_for_version(:latest)
    @test_client = TestClients::OpenAI.new(access_token: 'abc')
  end

  test "if a new message is created BEFORE job starts, it does not process" do
    @conversation.messages.create! role: :user, content_text: "You there?", assistant: @conversation.assistant

    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
    assert @message.content_text.blank?
    assert_nil @message.cancelled_at
  end

  test "if a new message is created AFTER job starts, it stops streaming - this tests the redis state" do
    m = @conversation.messages.create! role: :user, content_text: "And now?", assistant: @conversation.assistant
    @conversation.messages.where("id >= ?", m.id).delete_all # we are reverting the database change but the redis change persists

    assert_changes "@message.content_text", from: nil, to: @test_client.chat do
      assert_changes "@message.reload.cancelled_at", from: nil do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
      end
    end
  end

  test "if the cancel streaming button is clicked BEFORE job starts, it does not process" do
    @message.cancelled!

    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
    assert @message.content_text.blank?
    assert_not_nil @message.cancelled_at
  end

  test "if the cancel streaming button is clicked AFTER job starts, it does not process - this tests the redis state" do
    @message.cancelled! # this changes database column AND alters a redis state
    @message.update!(cancelled_at: nil) # this undoes the column change but the redis state persists

    assert_changes "@message.content_text", from: nil, to: @test_client.chat do
      assert_changes "@message.reload.cancelled_at", from: nil do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
      end
    end
  end
end

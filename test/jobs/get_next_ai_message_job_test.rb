require "test_helper"

class GetNextAIMessageJobOpenaiTest < ActiveJob::TestCase
  setup do
    TestChat.reset
    @conversation = conversations(:greeting)
    @user = @conversation.user
    @assistant = @conversation.assistant
    @assistant.language_model.update!(supports_tools: false)
    @conversation.messages.create! role: :user, content_text: "Are you still there?", assistant: @assistant
    @message = @conversation.latest_message_for_version(:latest)
  end

  test "if a new message is created BEFORE job starts, it does not process" do
    @conversation.messages.create! role: :user, content_text: "You there?", assistant: @assistant

    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert @message.content_text.blank?
    assert_nil @message.cancelled_at
  end

  test "if the cancel streaming button is clicked BEFORE job starts, it does not process" do
    @message.cancelled!

    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert @message.content_text.blank?
    assert_not_nil @message.cancelled_at
  end

  test "if message_cancelled? starts returning true for any reason AFTER job starts, it cancels the message" do
    false_on_first_run = 0
    job = GetNextAIMessageJob.new
    job.stub(:message_cancelled?, -> { false_on_first_run += 1; false_on_first_run != 1 }) do
      TestChat.text = "Hello"
      assert_changes "@message.content_text", from: nil, to: "Hello" do
        assert_changes "@message.reload.cancelled_at", from: nil do
          assert job.perform(@user.id, @message.id, @assistant.id)
        end
      end
    end
  end
end

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

  test "if the cancel streaming button is clicked BEFORE job starts, it does not process" do
    @message.cancelled!

    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
    assert @message.content_text.blank?
    assert_not_nil @message.cancelled_at
  end

  test "if message_cancelled? starts returning true for any reason AFTER job starts, it cancels the message" do
    # When the job first starts, it short circuits if the message is already cancelled so we are NOT going to
    # set the message to be cancelled Instead, we are going to stub out the message_cancelled? checker so it
    # returns true the first time it's used but false thereafter. This simulates message.cancelled! being
    # toggled after the job has started.
    false_on_first_run = 0
    job = GetNextAIMessageJob.new
    job.stub(:message_cancelled?, -> { false_on_first_run += 1; false_on_first_run != 1 }) do

      assert_changes "@message.content_text", from: nil, to: @test_client.chat do
        assert_changes "@message.reload.cancelled_at", from: nil do
          assert job.perform(@user.id, @message.id, @conversation.assistant.id)
        end
      end
    end
  end
end

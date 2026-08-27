require "test_helper"

class AutotitleConversationJobTest < ActiveJob::TestCase
  test "sets conversation title automatically when there are two messages" do
    conversation = conversations(:greeting)

    TestClient::OpenAI.stub :text, "{\"topic\":\"Hear me\"}" do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Hear me", conversation.reload.title
  end

  test "sets conversation title automatically even if there is only one message" do
    conversation = conversations(:javascript)
    conversation.latest_message_for_version(:latest).destroy!

    TestClient::OpenAI.stub :text, "{\"topic\":\"Javascript popState\"}" do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Javascript popState", conversation.reload.title
  end

  test "claude conversations are titled through the same intent path" do
    conversation = conversations(:hello_claude)

    TestClient::Anthropic.stub :text, "{\"topic\":\"Claude Summary\"}" do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Claude Summary", conversation.reload.title
  end

  test "gemini conversations are titled through the same intent path" do
    conversation = conversations(:gemini_conversation)

    TestClient::Gemini.stub :text, "{\"topic\":\"Gemini Summary\"}" do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Gemini Summary", conversation.reload.title
  end

  test "the job source stays provider-blind" do
    source = File.read(Rails.root.join("app/jobs/autotitle_conversation_job.rb"))

    [".scan(", ".driver ==", ".class =="].each do |needle|
      refute_includes source, needle
    end
  end

  test "the topic is not set if the conversation has no messages" do
    conversation = users(:keith).conversations.create!(assistant: assistants(:samantha))
    conversation.update!(updated_at: Time.current) # update is what triggers the callback

    assert_nothing_raised do # confirms the exception did not raise outside the job
      TestClient::OpenAI.stub :text, "{\"topic\":\"Javascript popState\"}" do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_nil conversation.reload.title # and confirm the job didn't do anything
  end
end

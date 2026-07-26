require "test_helper"

class AutotitleConversationJobRubyLLMTest < ActiveJob::TestCase
  include OptionsHelpers
  include RubyLLMTestHelpers

  setup do
    stub_features(rubyllm: true)
    TestClient::RubyLLM.function_stubbed = false
  end

  teardown do
    TestClient::RubyLLM.function_stubbed = false
  end

  test "flag on: sets conversation title from JSON response" do
    conversation = conversations(:greeting)

    TestClient::RubyLLM.stub :text, "{\"topic\":\"Hear me\"}" do
      stub_rubyllm_client do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_equal "Hear me", conversation.reload.title
  end

  test "flag on: works with one message" do
    conversation = conversations(:javascript)
    conversation.latest_message_for_version(:latest).destroy!

    TestClient::RubyLLM.stub :text, "{\"topic\":\"Javascript popState\"}" do
      stub_rubyllm_client do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_equal "Javascript popState", conversation.reload.title
  end

  test "flag off: existing OpenAI path unchanged" do
    stub_features(rubyllm: false) do
      conversation = conversations(:greeting)

      TestClient::OpenAI.stub :text, "{\"topic\":\"Legacy title\"}" do
        AutotitleConversationJob.perform_now(conversation.id)
      end

      assert_equal "Legacy title", conversation.reload.title
    end
  end

  test "flag on: regex fallback when response is not valid JSON" do
    conversation = conversations(:greeting)

    TestClient::RubyLLM.stub :text, 'The topic is:"Hear me"' do
      stub_rubyllm_client do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_equal "Hear me", conversation.reload.title
  end
end

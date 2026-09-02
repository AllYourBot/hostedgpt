require "test_helper"

class AutotitleConversationJobRubyLLMTest < ActiveJob::TestCase
  test "sets conversation title via RubyLLM" do
    conversation = conversations(:greeting)
    conversation.update!(title: nil)

    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub :text, '{"topic":"Hear me"}' do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_equal "Hear me", conversation.reload.title
  end

  test "unusable replies keep the prior title via RubyLLM" do
    conversation = conversations(:greeting)
    conversation.update!(title: nil)

    ["", "   ", "not json at all", "{\"topic\":\"\"}"].each do |reply|
      stub_features(use_ruby_llm: true) do
        TestClient::RubyLLM::Chat.stub :text, reply do
          AutotitleConversationJob.perform_now(conversation.id)
        end
      end
      assert_nil conversation.reload.title, "case #{reply.inspect} should leave the title untouched"
    end
  end
end

require "test_helper"

class AutotitleConversationJobTest < ActiveJob::TestCase
  test "sets conversation title automatically when there are two messages" do
    conversation = conversations(:greeting)
    conversation.update!(title: nil)

    TestClient::RubyLLM::Chat.stub :text, "{\"topic\":\"Hear me\"}" do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Hear me", conversation.reload.title
  end

  test "sets conversation title automatically even if there is only one message" do
    conversation = conversations(:javascript)
    conversation.latest_message_for_version(:latest).destroy!
    conversation.update!(title: nil)

    TestClient::RubyLLM::Chat.stub :text, "{\"topic\":\"Javascript popState\"}" do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Javascript popState", conversation.reload.title
  end

  test "claude conversations are titled through the same intent path" do
    conversation = conversations(:hello_claude)
    conversation.update!(title: nil)

    TestClient::RubyLLM::Chat.stub :text, "{\"topic\":\"Claude Summary\"}" do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Claude Summary", conversation.reload.title
  end

  test "a topic wrapped in a markdown json fence is still used" do
    conversation = conversations(:hello_claude)
    conversation.update!(title: nil)

    TestClient::RubyLLM::Chat.stub :text, "```json\n{ \"topic\": \"Vermont's capital\" }\n```" do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Vermont's capital", conversation.reload.title, "The fence should be stripped before parsing the JSON"
  end

  test "gemini conversations are titled through the same intent path" do
    conversation = conversations(:gemini_conversation)
    conversation.update!(title: nil)

    TestClient::RubyLLM::Chat.stub :text, "{\"topic\":\"Gemini Summary\"}" do
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

  test "a titled conversation never reaches the provider again" do
    conversation = conversations(:greeting)
    conversation.update!(title: "Already Named")

    assert_nothing_raised do
      TestClient::RubyLLM::Chat.stub :text, -> { raise "provider reached" } do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_equal "Already Named", conversation.reload.title
  end

  test "a title landing during the provider call survives the write" do
    conversation = conversations(:greeting)
    conversation.update!(title: nil)

    twin_class = Class.new(TestClient::RubyLLM::Chat) do
      define_singleton_method(:text) { "{\"topic\":\"Ladder Topic\"}" }

      define_method(:complete) do |&block|
        conversation.update!(title: "Twin Title")
        super(&block)
      end
    end

    AIBackend::RubyLLM.stub :gem_class, twin_class do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Twin Title", conversation.reload.title
  end

  test "provider network failures degrade to a warning instead of dead-lettering" do
    conversation = conversations(:greeting)
    conversation.update!(title: nil)

    failing_class = Class.new(TestClient::RubyLLM::Chat) do
      define_method(:complete) { |&block| raise Faraday::ConnectionFailed, "connection refused" }
    end

    warnings = []
    AIBackend::RubyLLM.stub :gem_class, failing_class do
      Rails.logger.stub :warn, ->(message) { warnings << message } do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_equal 1, warnings.length
    assert_includes warnings.first, conversation.id.to_s
    assert_nil conversation.reload.title
  end

  test "provider configuration errors degrade to a warning instead of dead-lettering" do
    conversation = conversations(:greeting)
    conversation.update!(title: nil)

    warnings = []
    AIBackend::RubyLLM.stub_any_instance :get_oneoff_message, -> (*) { raise AIBackend::ConfigurationError } do
      Rails.logger.stub :warn, ->(message) { warnings << message } do
        assert AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_equal 1, warnings.length
    assert_includes warnings.first, conversation.id.to_s
    assert_nil conversation.reload.title
  end

  test "a blank key skips title generation before any provider call" do
    conversation = conversations(:hello_groq)
    conversation.update!(title: nil)

    stub_features(default_llm_keys: false) do
      conversation.assistant.language_model.api_service.update!(token: "")

      assert_no_enqueued_jobs only: AutotitleConversationJob do
        refute AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_nil conversation.reload.title
  end

  test "a stalled provider call surfaces the HTTP timeout instead of dead-lettering" do
    # A stalled call stops at the HTTP layer (config.request_timeout) and
    # surfaces as Faraday::TimeoutError, which the job degrades like any
    # Faraday::Error — so this test raises rather than sleeping.
    conversation = conversations(:greeting)
    conversation.update!(title: nil)

    timing_out_class = Class.new(TestClient::RubyLLM::Chat) do
      define_method(:complete) { |&block| raise Faraday::TimeoutError, "execution expired" }
    end

    warnings = []
    AIBackend::RubyLLM.stub :gem_class, timing_out_class do
      Rails.logger.stub :warn, ->(message) { warnings << message } do
        assert AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_equal 1, warnings.length
    assert_includes warnings.first, "Provider failure"
    assert_nil conversation.reload.title
  end

  UNUSABLE_REPLIES = {
    empty_string: "",
    whitespace_only: "   ",
    plain_prose: "Here is a perfectly fine prose answer.",
    missing_key: "{}",
    blank_topic_value: "{\"topic\":\"\"}",
    numeric_topic: "{\"topic\":42}",
    array_topic: "{\"topic\":[\"a\",\"b\"]}",
    object_topic: "{\"topic\":{\"k\":\"v\"}}",
    not_json: "not json at all",
    null_literal: "null",
    true_literal: "true",
    false_literal: "false",
    hash_payload: { "topic" => 42 }
  }

  test "unusable replies keep the prior title instead of raising" do
    conversation = conversations(:greeting)
    conversation.update!(title: nil)

    UNUSABLE_REPLIES.each do |label, reply|
      warnings = []
      begin
        Rails.logger.stub :warn, ->(message) { warnings << message } do
          TestClient::RubyLLM::Chat.stub :text, reply do
            AutotitleConversationJob.perform_now(conversation.id)
          end
        end
      rescue StandardError => e
        flunk("case #{label} raised #{e.class}: #{e.message}")
      end
      assert_equal 1, warnings.length, "case #{label} should warn exactly once, got #{warnings.inspect}"
      assert_includes warnings.first, conversation.id.to_s, "case #{label} warning should carry the conversation id"
      assert_nil conversation.reload.title, "case #{label} should leave the title untouched"
    end
  end

  test "the topic is not set if the conversation has no messages" do
    conversation = users(:keith).conversations.create!(assistant: assistants(:samantha))
    conversation.update!(updated_at: Time.current) # update is what triggers the callback

    assert_nothing_raised do # confirms the exception did not raise outside the job
      TestClient::RubyLLM::Chat.stub :text, "{\"topic\":\"Javascript popState\"}" do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_nil conversation.reload.title # and confirm the job didn't do anything
  end
end

require "test_helper"

class AIBackend::RubyLLMTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:attachments)
    @assistant = assistants(:keith_gpt4)
    @user = @conversation.user
    @openai_service = api_services(:keith_openai_service)
    @anthropic_service = api_services(:keith_anthropic_service)
    @gemini_service = api_services(:keith_gemini_service)
  end

  # Phase 1 — updated for Phase 2 driver support

  test "supports_driver? returns true for openai, false for others in Phase 2" do
    assert AIBackend::RubyLLM.supports_driver?("openai")
    refute AIBackend::RubyLLM.supports_driver?("anthropic")
    refute AIBackend::RubyLLM.supports_driver?("gemini")
  end

  test "APIService#ai_backend returns old OpenAI class when feature flag is off" do
    stub_features(use_ruby_llm: false) do
      assert_equal AIBackend::OpenAI, @openai_service.ai_backend
    end
  end

  test "APIService#ai_backend returns old Anthropic class when feature flag is off" do
    stub_features(use_ruby_llm: false) do
      assert_equal AIBackend::Anthropic, @anthropic_service.ai_backend
    end
  end

  test "APIService#ai_backend returns old Gemini class when feature flag is off" do
    stub_features(use_ruby_llm: false) do
      assert_equal AIBackend::Gemini, @gemini_service.ai_backend
    end
  end

  test "APIService#ai_backend returns RubyLLM when flag on and driver is openai" do
    stub_features(use_ruby_llm: true) do
      assert_equal AIBackend::RubyLLM, @openai_service.ai_backend
    end
  end

  test "APIService#ai_backend falls back to old classes for unsupported drivers even with flag on" do
    stub_features(use_ruby_llm: true) do
      assert_equal AIBackend::Anthropic, @anthropic_service.ai_backend
      assert_equal AIBackend::Gemini, @gemini_service.ai_backend
    end
  end

  test "client returns TestClient::RubyLLM in test environment" do
    assert_equal TestClient::RubyLLM, AIBackend::RubyLLM.client
  end

  # Phase 2 — plain text chat, OpenAI only

  test "get_oneoff_message returns text content" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    TestClient::RubyLLM::Chat.stub :text, "Hello, world!" do
      assert_equal "Hello, world!", backend.get_oneoff_message("You are helpful", ["Hi"])
    end
  end

  test "get_oneoff_message passes instructions to chat" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    TestClient::RubyLLM::Chat.stub :text, "Test" do
      backend.get_oneoff_message("Be a poet", ["Hello"])
    end
    assert_equal "Be a poet", TestClient::RubyLLM::Chat.instructions
  end

  test "get_oneoff_message passes params to chat" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    TestClient::RubyLLM::Chat.stub :text, "Test" do
      backend.get_oneoff_message("You are helpful", ["Hi"], { temperature: 0.5 })
    end
    assert_equal({ temperature: 0.5 }, TestClient::RubyLLM::Chat.params)
  end

  test "get_oneoff_message adds preceding messages" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    chat = TestClient::RubyLLM::Chat.new(model: "gpt-4o", provider: :openai, assume_model_exists: true)
    TestClient::RubyLLM::Chat.stub :new, chat do
      TestClient::RubyLLM::Chat.stub :text, "Test" do
        backend.get_oneoff_message("You are helpful", ["First", "Second"])
      end
    end
    assert_equal 2, chat.messages.length
    assert_equal "user", chat.messages.first[:role]
    assert_equal "First", chat.messages.first[:content]
    assert_equal "assistant", chat.messages.last[:role]
    assert_equal "Second", chat.messages.last[:content]
  end

  test "stream_next_conversation_message yields chunk content" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    TestClient::RubyLLM::Chat.stub :text, "Streaming response" do
      chunks = []
      result = backend.stream_next_conversation_message { |c| chunks << c }
      assert_equal ["Streaming response"], chunks
      assert_nil result
    end
  end

  test "stream_handler accumulates multiple chunks and captures tokens" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    backend.instance_variable_set(:@stream_response_text, "")
    handler = backend.send(:stream_handler)

    chunk1 = OpenStruct.new(content: "Hello ", input_tokens: nil, output_tokens: nil)
    chunk2 = OpenStruct.new(content: "world!", input_tokens: 10, output_tokens: 3)

    chunks = []
    handler.call(chunk1, ->(c) { chunks << c })
    handler.call(chunk2, ->(c) { chunks << c })

    assert_equal ["Hello ", "world!"], chunks
    assert_equal 10, message.input_token_count
    assert_equal 3, message.output_token_count
  end

  test "stream_handler captures token counts on first occurrence" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    backend.instance_variable_set(:@stream_response_text, "")
    handler = backend.send(:stream_handler)

    token_chunk = OpenStruct.new(content: "Hi", input_tokens: 100, output_tokens: 50)
    handler.call(token_chunk, ->(c) { })

    assert_equal 100, message.input_token_count
    assert_equal 50, message.output_token_count
  end

  test "stream_next_conversation_message raises Faraday::ParsingError on blank response" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    TestClient::RubyLLM::Chat.stub :text, "" do
      assert_raises(Faraday::ParsingError) do
        backend.stream_next_conversation_message { |c| }
      end
    end
  end

  test "stream_handler raises ConfigurationError on unauthorized" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    handler = backend.send(:stream_handler)

    error_chunk = OpenStruct.new
    error_chunk.define_singleton_method(:content) { raise ::RubyLLM::UnauthorizedError, "Unauthorized" }
    error_chunk.define_singleton_method(:input_tokens) { nil }
    error_chunk.define_singleton_method(:output_tokens) { nil }

    assert_raises(AIBackend::RubyLLM::ConfigurationError) do
      handler.call(error_chunk, ->(c) { })
    end
  end

  test "stream_handler raises RateLimitError on rate limit" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    handler = backend.send(:stream_handler)

    error_chunk = OpenStruct.new
    error_chunk.define_singleton_method(:content) { raise ::RubyLLM::RateLimitError, "Rate limited" }
    error_chunk.define_singleton_method(:input_tokens) { nil }
    error_chunk.define_singleton_method(:output_tokens) { nil }

    assert_raises(AIBackend::RubyLLM::RateLimitError) do
      handler.call(error_chunk, ->(c) { })
    end
  end

  test "stream_handler re-raises ResponseCancelled" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    handler = backend.send(:stream_handler)

    error_chunk = OpenStruct.new
    error_chunk.define_singleton_method(:content) { raise GetNextAIMessageJob::ResponseCancelled }
    error_chunk.define_singleton_method(:input_tokens) { nil }
    error_chunk.define_singleton_method(:output_tokens) { nil }

    assert_raises(GetNextAIMessageJob::ResponseCancelled) do
      handler.call(error_chunk, ->(c) { })
    end
  end

  test "preceding_conversation_messages returns messages with role and content" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    msgs = backend.send(:preceding_conversation_messages)

    assert msgs.present?
    msgs.each do |msg|
      assert_includes msg, :role
      assert_includes msg, :content
      refute_equal "tool", msg[:role].to_s
    end
  end

  test "test_execute returns content for valid model" do
    TestClient::RubyLLM::Chat.stub :text, "Hi there!" do
      result = AIBackend::RubyLLM.test_execute("https://api.openai.com/v1/", "abc", "gpt-4o")
      assert_equal "Hi there!", result
    end
  end

  test "initialize raises ConfigurationError when token is blank" do
    stub_features(default_llm_keys: false) do
      service = @assistant.language_model.api_service
      service.update!(token: "")

      assert_raises(AIBackend::RubyLLM::ConfigurationError) do
        AIBackend::RubyLLM.new(@user, @assistant)
      end
    end
  end

  test "initialize does not raise when token is present" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    assert_instance_of AIBackend::RubyLLM, backend
  end

  test "ruby_llm_context sets openai_api_base for Groq" do
    @assistant.language_model.api_service.update!(url: APIService::URL_GROQ, driver: "openai")
    backend = AIBackend::RubyLLM.new(@user, @assistant)

    context = backend.send(:ruby_llm_context)
    assert_equal APIService::URL_GROQ, context.openai_api_base
  end

  test "ruby_llm_context does not set openai_api_base for canonical OpenAI URL" do
    @assistant.language_model.api_service.update!(url: APIService::URL_OPEN_AI, driver: "openai")
    backend = AIBackend::RubyLLM.new(@user, @assistant)

    context = backend.send(:ruby_llm_context)
    assert_nil context.openai_api_base
  end
end

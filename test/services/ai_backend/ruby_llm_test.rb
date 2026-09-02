require "test_helper"

class AIBackend::RubyLLMTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @conversation = conversations(:attachments)
    @assistant = assistants(:keith_gpt4)
    @user = @conversation.user
    @openai_service = api_services(:keith_openai_service)
    @anthropic_service = api_services(:keith_anthropic_service)
    @gemini_service = api_services(:keith_gemini_service)
  end

  # Phase 1 — updated for Phase 3 driver support

  test "supports_driver? returns true for all backends in Phase 3" do
    assert AIBackend::RubyLLM.supports_driver?("openai")
    assert AIBackend::RubyLLM.supports_driver?("anthropic")
    assert AIBackend::RubyLLM.supports_driver?("gemini")
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

  test "APIService#ai_backend returns RubyLLM for all drivers when flag is on in Phase 3" do
    stub_features(use_ruby_llm: true) do
      assert_equal AIBackend::RubyLLM, @openai_service.ai_backend
      assert_equal AIBackend::RubyLLM, @anthropic_service.ai_backend
      assert_equal AIBackend::RubyLLM, @gemini_service.ai_backend
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

  test "stream_handler raises Faraday::TooManyRequestsError on rate limit" do
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

    assert_raises(Faraday::TooManyRequestsError) do
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

  # Phase 3 — Anthropic + Gemini/Groq text chat

  test "provider_for_url returns anthropic for Anthropic URL" do
    assert_equal :anthropic, AIBackend::RubyLLM.provider_for_url(APIService::URL_ANTHROPIC)
  end

  test "provider_for_url returns gemini for Gemini URL" do
    assert_equal :gemini, AIBackend::RubyLLM.provider_for_url(APIService::URL_GEMINI)
  end

  test "provider_for_url returns openai for OpenAI URL" do
    assert_equal :openai, AIBackend::RubyLLM.provider_for_url(APIService::URL_OPEN_AI)
  end

  test "provider_for_url returns openai for Groq URL" do
    assert_equal :openai, AIBackend::RubyLLM.provider_for_url(APIService::URL_GROQ)
  end

  test "test_execute uses anthropic provider for Anthropic URL" do
    TestClient::RubyLLM::Chat.stub :text, "Bonjour" do
      result = AIBackend::RubyLLM.test_execute(APIService::URL_ANTHROPIC, "abc", "claude-3-opus")
      assert_equal "Bonjour", result
    end
  end

  test "test_execute uses gemini provider for Gemini URL" do
    TestClient::RubyLLM::Chat.stub :text, "Hallo" do
      result = AIBackend::RubyLLM.test_execute(APIService::URL_GEMINI, "abc", "gemini-pro")
      assert_equal "Hallo", result
    end
  end

  test "ruby_llm_context sets anthropic_api_key for anthropic driver" do
    @assistant.language_model.api_service.update!(driver: "anthropic")
    backend = AIBackend::RubyLLM.new(@user, @assistant)

    context = backend.send(:ruby_llm_context)
    assert_equal @assistant.language_model.api_service.effective_token, context.anthropic_api_key
  end

  test "ruby_llm_context sets gemini_api_key for gemini driver" do
    @assistant.language_model.api_service.update!(driver: "gemini")
    backend = AIBackend::RubyLLM.new(@user, @assistant)

    context = backend.send(:ruby_llm_context)
    assert_equal @assistant.language_model.api_service.effective_token, context.gemini_api_key
  end

  test "build_chat uses provider_slug for anthropic" do
    @assistant.language_model.api_service.update!(driver: "anthropic")
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    chat_class = AIBackend::RubyLLM.gem_class

    chat_class.stub :new, ->(**kwargs) { kwargs } do
      chat_args = backend.send(:build_chat)
      assert_equal :anthropic, chat_args[:provider]
    end
  end

  test "build_chat uses provider_slug for gemini" do
    @assistant.language_model.api_service.update!(driver: "gemini")
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    chat_class = AIBackend::RubyLLM.gem_class

    chat_class.stub :new, ->(**kwargs) { kwargs } do
      chat_args = backend.send(:build_chat)
      assert_equal :gemini, chat_args[:provider]
    end
  end

  test "stream_next_conversation_message works with anthropic driver" do
    @assistant.language_model.api_service.update!(driver: "anthropic")
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    TestClient::RubyLLM::Chat.stub :text, "Claude streaming" do
      chunks = []
      result = backend.stream_next_conversation_message { |c| chunks << c }
      assert_equal ["Claude streaming"], chunks
      assert_nil result
    end
  end

  test "stream_next_conversation_message works with gemini driver" do
    @assistant.language_model.api_service.update!(driver: "gemini")
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    TestClient::RubyLLM::Chat.stub :text, "Gemini streaming" do
      chunks = []
      result = backend.stream_next_conversation_message { |c| chunks << c }
      assert_equal ["Gemini streaming"], chunks
      assert_nil result
    end
  end

  # Phase 4 — Image/PDF attachment parity

  test "preceding_conversation_messages includes image attachments when supports_images is true" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_images: true, supports_tools: false)
    conversation = conversations(:attachments)
    message = conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: assistant,
      index: conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, assistant, conversation, message)
    msgs = backend.send(:preceding_conversation_messages)

    message_with_attachments = msgs.find { |m| m[:content].is_a?(::RubyLLM::Content) }
    assert message_with_attachments, "Should find a message with RubyLLM::Content for image attachments"
    assert message_with_attachments[:content].attachments.any?, "Content should have attachments"
  end

  test "preceding_conversation_messages does not include attachments when supports_images is false" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_images: false, supports_tools: false)
    conversation = conversations(:attachments)
    message = conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: assistant,
      index: conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, assistant, conversation, message)
    msgs = backend.send(:preceding_conversation_messages)

    msgs_with_attachments = msgs.filter_map { |m| m if m[:content].is_a?(::RubyLLM::Content) }
    assert_empty msgs_with_attachments, "Should not have any Content objects when supports_images is false"
  end

  test "preceding_conversation_messages inlines PDF text when supports_images is true" do
    pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n/F1 12 Tf\n72 720 Td\n(Hello World) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000200 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n294\n%%EOF"

    test_file = Tempfile.new(["test", ".pdf"])
    test_file.write(pdf_content)
    test_file.rewind

    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_images: true, supports_tools: false)

    conversation = Conversation.create!(user: @user, assistant: assistant, title: "PDF Test")

    pdf_message = conversation.messages.create!(
      role: "user",
      content_text: "Check this document",
      assistant: assistant
    )
    pdf_message.documents.create!(
      file: fixture_file_upload(test_file.path, "application/pdf"),
      filename: "test.pdf"
    )

    message = conversation.messages.create!(
      role: "assistant",
      content_text: "Let me check",
      assistant: assistant
    )

    backend = AIBackend::RubyLLM.new(@user, assistant, conversation, message)
    msgs = backend.send(:preceding_conversation_messages)

    pdf_entry = msgs.find { |m| m[:role] == "user" && m[:content].to_s.include?("PDF Document: test.pdf") }
    assert pdf_entry, "Should include PDF content reference"
    assert pdf_entry[:content].to_s.include?("PDF Document: test.pdf"), "Should include PDF document reference"
    assert pdf_entry[:content].to_s.include?("Unable to extract text from this PDF"), "Should include error for failed extraction"
  ensure
    test_file&.close
    test_file&.unlink
  end

  test "sanitize_content removes json_of_generated_image from JSON content" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: '{"prompt_given":"cat","json_of_generated_image":"base64data","message_to_user":"image"}',
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    result = backend.send(:sanitize_content, message)

    parsed = JSON.parse(result)
    refute parsed.has_key?("json_of_generated_image"), "Should remove json_of_generated_image"
    assert_equal "cat", parsed["prompt_given"]
  end

  test "sanitize_content passes through plain text unchanged" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: "Hello, how are you?",
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    result = backend.send(:sanitize_content, message)

    assert_equal "Hello, how are you?", result
  end

  test "sanitize_content returns empty string for nil content" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    result = backend.send(:sanitize_content, message)

    assert_equal "", result
  end

  test "stream_next_conversation_message works with image attachments" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_images: true, supports_tools: false)
    conversation = conversations(:attachments)
    message = conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: assistant,
      index: conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, assistant, conversation, message)
    TestClient::RubyLLM::Chat.stub :text, "I see a cat" do
      chunks = []
      result = backend.stream_next_conversation_message { |c| chunks << c }
      assert_equal ["I see a cat"], chunks
      assert_nil result
    end
  end

  test "image attachment streaming produces vision response with openai driver" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.api_service.update!(driver: "openai")
    assistant.language_model.update!(supports_images: true, supports_tools: false)
    conversation = conversations(:attachments)
    message = conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: assistant,
      index: conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, assistant, conversation, message)
    TestClient::RubyLLM::Chat.stub :text, "OpenAI sees a feline" do
      chunks = []
      result = backend.stream_next_conversation_message { |c| chunks << c }
      assert_equal ["OpenAI sees a feline"], chunks
      assert_nil result
    end
  end

  test "image attachment streaming produces vision response with anthropic driver" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.api_service.update!(driver: "anthropic")
    assistant.language_model.update!(supports_images: true, supports_tools: false)
    conversation = conversations(:attachments)
    message = conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: assistant,
      index: conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, assistant, conversation, message)
    TestClient::RubyLLM::Chat.stub :text, "Claude sees a feline" do
      chunks = []
      result = backend.stream_next_conversation_message { |c| chunks << c }
      assert_equal ["Claude sees a feline"], chunks
      assert_nil result
    end
  end

  test "image attachment streaming produces vision response with gemini driver" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.api_service.update!(driver: "gemini")
    assistant.language_model.update!(supports_images: true, supports_tools: false)
    conversation = conversations(:attachments)
    message = conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: assistant,
      index: conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, assistant, conversation, message)
    TestClient::RubyLLM::Chat.stub :text, "Gemini sees a feline" do
      chunks = []
      result = backend.stream_next_conversation_message { |c| chunks << c }
      assert_equal ["Gemini sees a feline"], chunks
      assert_nil result
    end
  end

  test "preceding_conversation_messages preserves text alongside image attachments" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_images: true, supports_tools: false)
    conversation = conversations(:attachments)
    message = conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: assistant,
      index: conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, assistant, conversation, message)
    msgs = backend.send(:preceding_conversation_messages)

    mixed_msg = msgs.find { |m| m[:content].is_a?(::RubyLLM::Content) }
    assert mixed_msg, "Should find a message with mixed content"
    assert mixed_msg[:content].text.present?, "Content text should be preserved alongside attachments"
    assert mixed_msg[:content].attachments.any?, "Attachments should be present"
  end

  # Phase 5 — Tool/function calling parity

  test "ConfigurationError inherits from AIBackend::ConfigurationError" do
    assert AIBackend::RubyLLM::ConfigurationError < AIBackend::ConfigurationError
  end

  test "get_oneoff_message with json: true appends a JSON-coercion instruction" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    TestClient::RubyLLM::Chat.stub :text, '{"topic":"Hi"}' do
      backend.get_oneoff_message("Extract a topic", ["Hello"], json: true)
    end
    assert_includes TestClient::RubyLLM::Chat.instructions, "Respond with ONLY valid JSON"
  end

  test "get_oneoff_message without json does not append the JSON instruction" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    TestClient::RubyLLM::Chat.stub :text, "Plain" do
      backend.get_oneoff_message("Extract a topic", ["Hello"])
    end
    refute_includes TestClient::RubyLLM::Chat.instructions, "Respond with ONLY valid JSON"
  end

  test "tool_instances maps each Toolbox tool to an InterceptedTool" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    instances = backend.send(:tool_instances)

    assert instances.all? { |i| i.is_a?(AIBackend::RubyLLM::InterceptedTool) }
    assert_includes instances.map(&:name), "helloworld_hi"
    assert_includes instances.map(&:name), "openmeteo_get_current_and_todays_weather"
  end

  test "tools are not enabled for Groq URL" do
    @assistant.language_model.api_service.update!(url: APIService::URL_GROQ, driver: "openai")
    @assistant.language_model.update!(supports_tools: true)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    assert_not backend.send(:tools_enabled?)
  end

  test "tools are enabled for a canonical OpenAI service when supports_tools is true" do
    @assistant.language_model.update!(supports_tools: true)
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    assert backend.send(:tools_enabled?)
  end

  test "stream_next_conversation_message returns a formatted tool call when the model requests one" do
    @assistant.language_model.update!(supports_tools: true)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    TestClient::RubyLLM::Chat.stub :function, "helloworld_hi" do
      result = backend.stream_next_conversation_message { |c| }
      assert_equal 1, result.length
      assert_equal "function", result[0][:type]
      assert_equal "helloworld_hi", result[0][:function][:name]
      assert_equal TestClient::RubyLLM::Chat.id, result[0][:id]
      assert_includes result[0][:function][:arguments], "Austin"
    end
  end

  test "stream_next_conversation_message returns parallel tool calls with distinct ids" do
    @assistant.language_model.update!(supports_tools: true)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    TestClient::RubyLLM::Chat.stub :function, "helloworld_hi" do
      TestClient::RubyLLM::Chat.stub :num_tool_calls, 2 do
        result = backend.stream_next_conversation_message { |c| }
        assert_equal 2, result.length
        assert_equal [0, 1], result.map { |tc| tc[:index] }
        assert_operator result.map { |tc| tc[:id] }.uniq.length, :>, 1
      end
    end
  end

  test "preceding_conversation_messages replays tool calls and tool results" do
    @assistant.language_model.update!(supports_tools: true)
    conversation = @conversation

    conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      content_tool_calls: [
        { type: "function", id: "call_123", function: { name: "helloworld_hi", arguments: '{"name":"Keith"}' } },
      ]
    )
    conversation.messages.create!(
      role: :tool,
      content_text: "Hello, Keith!".to_json,
      assistant: @assistant,
      tool_call_id: "call_123",
      content_tool_calls: [
        { type: "function", id: "call_123", function: { name: "helloworld_hi", arguments: '{"name":"Keith"}' } },
      ]
    )
    follow_up = conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, conversation, follow_up)
    msgs = backend.send(:preceding_conversation_messages)

    tool_replay = msgs.find { |m| m[:role] == :tool }
    assert tool_replay, "expected a tool result message to be replayed"
    assert_equal "call_123", tool_replay[:tool_call_id]
    assert_equal "Hello, Keith!".to_json, tool_replay[:content]

    assistant_replay = msgs.find { |m| m[:role] == :assistant && m[:tool_calls].present? }
    assert assistant_replay, "expected the assistant tool-call message to be replayed"
    assert_equal "helloworld_hi", assistant_replay[:tool_calls]["call_123"].name
    assert_equal({ "name" => "Keith" }, assistant_replay[:tool_calls]["call_123"].arguments)
  end

  # Error contract: errors raised at the chat.complete boundary (where the gem
  # raises them) must map to the unified contract, not only chunk-level errors.

  test "stream_next_conversation_message maps a complete-level UnauthorizedError to ConfigurationError" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    TestClient::RubyLLM::Chat.stub :error_to_raise, ::RubyLLM::UnauthorizedError.new("401 bad key") do
      assert_raises(AIBackend::RubyLLM::ConfigurationError) do
        backend.stream_next_conversation_message { |c| }
      end
    end
  end

  test "stream_next_conversation_message maps a complete-level RateLimitError to Faraday::TooManyRequestsError" do
    @assistant.language_model.update!(supports_tools: false)
    message = @conversation.messages.create!(
      role: :assistant,
      content_text: nil,
      assistant: @assistant,
      index: @conversation.messages.maximum(:index).to_i + 1,
      version: :latest
    )

    backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, message)
    TestClient::RubyLLM::Chat.stub :error_to_raise, ::RubyLLM::RateLimitError.new("429 rate limited") do
      assert_raises(Faraday::TooManyRequestsError) do
        backend.stream_next_conversation_message { |c| }
      end
    end
  end

  test "get_oneoff_message maps a complete-level UnauthorizedError to ConfigurationError" do
    backend = AIBackend::RubyLLM.new(@user, @assistant)
    TestClient::RubyLLM::Chat.stub :error_to_raise, ::RubyLLM::UnauthorizedError.new("401 bad key") do
      assert_raises(AIBackend::RubyLLM::ConfigurationError) do
        backend.get_oneoff_message("Extract a topic", ["Hello"])
      end
    end
  end
end

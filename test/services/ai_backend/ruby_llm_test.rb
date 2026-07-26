require "test_helper"

class AIBackend::RubyLLMTest < ActiveSupport::TestCase
  include OptionsHelpers
  include RubyLLMTestHelpers

  setup do
    stub_features(rubyllm: true)

    @conversation = conversations(:greeting)
    @user = @conversation.user
    @assistant = @conversation.assistant
    @assistant.language_model.update!(supports_tools: false)
    @conversation.messages.create! role: :user, content_text: "Are you still there?", assistant: @assistant
    @message = @conversation.latest_message_for_version(:latest)
    TestClient::RubyLLM.function_stubbed = false
  end

  teardown do
    TestClient::RubyLLM.function_stubbed = false
  end

  test "stream_next_conversation_message yields text chunks" do
    TestClient::RubyLLM.stub :text, "Hello from RubyLLM" do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        chunks = []
        backend.stream_next_conversation_message { |chunk| chunks << chunk }

        assert_equal ["Hello from RubyLLM"], chunks
        assert_equal "Hello from RubyLLM", backend.instance_variable_get(:@stream_response_text)
      end
    end
  end

  test "stream_next_conversation_message sets token counts on message" do
    TestClient::RubyLLM.stub :text, "Hello" do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)
        backend.stream_next_conversation_message { |_| }

        assert_equal 10, @message.input_token_count
        assert_equal 20, @message.output_token_count
      end
    end
  end

  test "get_oneoff_message returns the response content" do
    TestClient::RubyLLM.stub :text, "One-off reply" do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant)
        result = backend.get_oneoff_message("You are helpful", ["Hi there"])

        assert_equal "One-off reply", result
      end
    end
  end

  test "blank token raises AIBackend::RubyLLM::ConfigurationError" do
    @assistant.api_service.update!(token: nil)

    assert_raises(AIBackend::RubyLLM::ConfigurationError) do
      AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)
    end
  end

  test "RubyLLM::UnauthorizedError is re-raised as AIBackend::RubyLLM::ConfigurationError in stream" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::UnauthorizedError, "bad key" } do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        assert_raises(AIBackend::RubyLLM::ConfigurationError) do
          backend.stream_next_conversation_message { |_| }
        end
      end
    end
  end

  test "RubyLLM::RateLimitError is re-raised as AIBackend::RubyLLM::RateLimitError in stream" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::RateLimitError, "slow down" } do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        assert_raises(AIBackend::RubyLLM::RateLimitError) do
          backend.stream_next_conversation_message { |_| }
        end
      end
    end
  end

  test "RubyLLM::ConfigurationError is re-raised as AIBackend::RubyLLM::ConfigurationError in stream" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::ConfigurationError, "not configured" } do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        assert_raises(AIBackend::RubyLLM::ConfigurationError) do
          backend.stream_next_conversation_message { |_| }
        end
      end
    end
  end

  test "RubyLLM::ForbiddenError is re-raised as AIBackend::RubyLLM::ConfigurationError" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::ForbiddenError, "forbidden" } do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        assert_raises(AIBackend::RubyLLM::ConfigurationError) do
          backend.stream_next_conversation_message { |_| }
        end
      end
    end
  end

  test "RubyLLM::PaymentRequiredError is re-raised as AIBackend::RubyLLM::RateLimitError" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::PaymentRequiredError, "payment required" } do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        assert_raises(AIBackend::RubyLLM::RateLimitError) do
          backend.stream_next_conversation_message { |_| }
        end
      end
    end
  end

  test "RubyLLM::UnauthorizedError is re-raised as AIBackend::RubyLLM::ConfigurationError in get_oneoff_message" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::UnauthorizedError, "bad key" } do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant)

        assert_raises(AIBackend::RubyLLM::ConfigurationError) do
          backend.get_oneoff_message("instructions", ["text"])
        end
      end
    end
  end

  test "RubyLLM::RateLimitError is re-raised as AIBackend::RubyLLM::RateLimitError in get_oneoff_message" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::RateLimitError, "slow down" } do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant)

        assert_raises(AIBackend::RubyLLM::RateLimitError) do
          backend.get_oneoff_message("instructions", ["text"])
        end
      end
    end
  end

  test "preceding_conversation_messages converts messages with correct roles and content" do
    stub_rubyllm_client do
      backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)
      messages = backend.send(:preceding_conversation_messages)

      assert messages.length >= 2
      assert_equal :user, messages[0][:role]
      assert_equal "Can you hear <b>me</b>? I live in Austin, Texas", messages[0][:content]
      assert_equal :assistant, messages[1][:role]
      assert_equal "Yes, I can hear you. How can I help you today?", messages[1][:content]
    end
  end

  test "tool calling returns tool calls in OpenAI format" do
    @assistant.language_model.update!(supports_tools: true)

    TestClient::RubyLLM.function_stubbed = true
    TestClient::RubyLLM.stub :function, "helloworld_hi" do
      TestClient::RubyLLM.stub :arguments, { name: "Keith" }.to_json do
        stub_rubyllm_client do
          backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

          chunks = []
          result = backend.stream_next_conversation_message { |chunk| chunks << chunk }

          assert result.present?, "Should return tool calls"
          assert_equal "helloworld_hi", result.dig(0, "function", "name")
          assert_equal "call_BlAN9iRiAD6aCzmBWCjzYxjj", result.dig(0, "id")
        end
      end
    end
  end

  test "tool_instances converts Toolbox.tools to InterceptedTool objects" do
    @assistant.language_model.update!(supports_tools: true)
    stub_rubyllm_client do
      backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)
      tools = backend.send(:tool_instances)

      assert tools.any? { |t| t.name == "helloworld_hi" }
      assert tools.all? { |t| t.is_a?(AIBackend::RubyLLM::InterceptedTool) }
    end
  end

  test "preceding_conversation_messages handles images via RubyLLM::Content::Raw" do
    stub_rubyllm_client do
      conversation = conversations(:attachments)
      assistant = assistants(:keith_gpt4)
      assistant.language_model.update!(supports_tools: false)
      message = conversation.latest_message_for_version(:latest)

      backend = AIBackend::RubyLLM.new(users(:keith), assistant, conversation, message)
      messages = backend.send(:preceding_conversation_messages)

      has_raw_content = false
      messages.each do |msg|
        if msg[:content].is_a?(::RubyLLM::Content::Raw)
          has_raw_content = true
          content = msg[:content].value
          assert content.is_a?(Array)
          assert_equal "text", content.first[:type]
        end
      end
      assert has_raw_content, "Expected at least one message with RubyLLM::Content::Raw"
    end
  end

  test "preceding_conversation_messages uses plain text when supports_images is false" do
    stub_rubyllm_client do
      backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)
      messages = backend.send(:preceding_conversation_messages)

      messages.each do |msg|
        assert msg[:content].is_a?(String), "Content should be plain text, not Raw"
      end
    end
  end

  test "preceding_conversation_messages builds tool_calls as Hash keyed by id" do
    stub_rubyllm_client do
      conversation = conversations(:weather)
      message = messages(:weather_explained)
      assistant = message.assistant
      user = message.user

      backend = AIBackend::RubyLLM.new(user, assistant, conversation, message)
      msgs = backend.send(:preceding_conversation_messages)

      tool_msg = msgs.find { |m| m[:tool_calls].present? }
      assert tool_msg, "Expected a message with tool_calls"
      assert tool_msg[:tool_calls].is_a?(Hash), "tool_calls should be a Hash, got #{tool_msg[:tool_calls].class}"
      assert tool_msg[:tool_calls].values.all? { |tc| tc.is_a?(::RubyLLM::ToolCall) }
    end
  end

  test "ResponseCancelled propagates through stream_handler" do
    TestClient::RubyLLM.stub :text, "Hello" do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        assert_raises(GetNextAIMessageJob::ResponseCancelled) do
          backend.stream_next_conversation_message { |_| raise GetNextAIMessageJob::ResponseCancelled }
        end
      end
    end
  end

  test "NoMethodError propagates through stream_handler" do
    TestClient::RubyLLM.stub :text, "Hello" do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        assert_raises(NoMethodError) do
          backend.stream_next_conversation_message { |_| raise NoMethodError, "test" }
        end
      end
    end
  end

  test "sanitized_tool_content strips message_to_user and json_of_generated_image" do
    stub_rubyllm_client do
      message = Message.new(role: :tool, content_text: '{"answer":"yes","message_to_user":"shown","json_of_generated_image":"base64"}')
      backend = AIBackend::RubyLLM.new(@user, @assistant)
      result = backend.send(:sanitized_tool_content, message)

      parsed = JSON.parse(result)
      assert_equal "yes", parsed["answer"]
      refute parsed.key?("message_to_user")
      refute parsed.key?("json_of_generated_image")
    end
  end

  test "sanitized_tool_content passes through non-JSON tool content" do
    stub_rubyllm_client do
      message = Message.new(role: :tool, content_text: "Hello, Keith!")
      backend = AIBackend::RubyLLM.new(@user, @assistant)
      result = backend.send(:sanitized_tool_content, message)

      assert_equal "Hello, Keith!", result
    end
  end

  test "sanitized_tool_content returns plain text for non-tool messages" do
    stub_rubyllm_client do
      message = Message.new(role: :user, content_text: "Hi there")
      backend = AIBackend::RubyLLM.new(@user, @assistant)
      result = backend.send(:sanitized_tool_content, message)

      assert_equal "Hi there", result
    end
  end

  test "preceding_conversation_messages rescues JSON::ParserError on malformed tool_call arguments" do
    stub_rubyllm_client do
      conversation = conversations(:weather)
      message = messages(:weather_tool_call)
      message.update!(content_tool_calls: [{ "id" => "bad_call", "type" => "function", "function" => { "name" => "test_fn", "arguments" => "{invalid json}" } }])

      reply = conversation.messages.create!(role: :assistant, content_text: nil, assistant: @assistant)

      backend = AIBackend::RubyLLM.new(@user, @assistant, conversation, reply)
      messages = backend.send(:preceding_conversation_messages)

      tool_msg = messages.find { |m| m[:tool_calls].present? }
      assert tool_msg, "Expected a message with tool_calls"
      tc = tool_msg[:tool_calls].values.first
      assert_equal "test_fn", tc.name
      assert_equal({}, tc.arguments, "Malformed JSON should fall back to empty hash")
    end
  end

  test "provider_for_url infers correct provider from URL" do
    assert_equal :anthropic, AIBackend::RubyLLM.send(:provider_for_url, "https://api.anthropic.com/")
    assert_equal :gemini, AIBackend::RubyLLM.send(:provider_for_url, "https://generativelanguage.googleapis.com/v1beta/")
    assert_equal :openai, AIBackend::RubyLLM.send(:provider_for_url, "https://api.openai.com/v1/")
    assert_equal :openai, AIBackend::RubyLLM.send(:provider_for_url, "https://api.groq.com/openai/v1/")
  end

  test "sanitized_tool_content returns raw string for non-Hash JSON tool content" do
    stub_rubyllm_client do
      message = Message.new(role: :tool, content_text: '[1, 2, 3]')
      backend = AIBackend::RubyLLM.new(@user, @assistant)
      result = backend.send(:sanitized_tool_content, message)

      assert_equal '[1, 2, 3]', result
    end
  end

  test "sanitized_tool_content returns empty string for nil content_text on non-tool messages" do
    stub_rubyllm_client do
      message = Message.new(role: :assistant, content_text: nil)
      backend = AIBackend::RubyLLM.new(@user, @assistant)
      result = backend.send(:sanitized_tool_content, message)

      assert_equal "", result
    end
  end

  test "stream_handler catch-all rescue swallows unexpected errors" do
    TestClient::RubyLLM.stub :text, "Hello" do
      stub_rubyllm_client do
        backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

        chunks = []
        result = backend.stream_next_conversation_message { |chunk|
          chunks << chunk
          raise StandardError, "unexpected" if chunk == "Hello"
        }

        assert_equal ["Hello"], chunks, "Should have received one chunk before error"
        assert_nil result, "Should return nil for text responses"
        assert_equal "Hello", backend.instance_variable_get(:@stream_response_text)
      end
    end
  end

  test "build_image_content returns Anthropic format for anthropic provider" do
    stub_rubyllm_client do
      assistant = assistants(:keith_claude3)
      backend = AIBackend::RubyLLM.new(users(:keith), assistant, @conversation, @message)
      result = backend.send(:build_image_content, mock_document)

      assert_equal "image", result[:type]
      assert_equal "base64", result.dig(:source, :type)
      assert_equal "image/png", result.dig(:source, :media_type)
      assert_equal "BASE64", result.dig(:source, :data)
    end
  end

  test "build_image_content returns Gemini format for gemini provider" do
    stub_rubyllm_client do
      assistant = assistants(:keith_gemini)
      backend = AIBackend::RubyLLM.new(users(:keith), assistant, @conversation, @message)
      result = backend.send(:build_image_content, mock_document)

      assert_equal "image/png", result.dig(:inline_data, :mime_type)
      assert_equal "BASE64", result.dig(:inline_data, :data)
    end
  end

  test "stream_next_conversation_message raises without block" do
    stub_rubyllm_client do
      backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)

      assert_raises(RuntimeError, "No chunk handler given") do
        backend.stream_next_conversation_message
      end
    end
  end

  test "format_tool_calls_from_response passes string arguments through unchanged" do
    stub_rubyllm_client do
      tc = ::RubyLLM::ToolCall.new(id: "call_1", name: "test_fn", arguments: '{"x":1}')
      @assistant.language_model.update!(supports_tools: true)
      backend = AIBackend::RubyLLM.new(@user, @assistant, @conversation, @message)
      result = backend.send(:format_tool_calls_from_response, { "call_1" => tc })

      assert_equal 1, result.length
      assert_equal "call_1", result.first["id"]
      assert_equal "test_fn", result.first.dig("function", "name")
      assert_equal '{"x":1}', result.first.dig("function", "arguments")
    end
  end

  test "InterceptedTool execute raises safety net error" do
    tool = AIBackend::RubyLLM::InterceptedTool.new(
      name: "test", description: "desc", params_schema: { type: "object", properties: {} }
    )
    assert_raises(RuntimeError, /should never be called/) do
      tool.execute(foo: "bar")
    end
  end

  private

  def mock_document
    doc = Object.new
    doc.define_singleton_method(:file) { OpenStruct.new(blob: OpenStruct.new(content_type: "image/png")) }
    doc.define_singleton_method(:file_base64) { |_| "BASE64" }
    doc.define_singleton_method(:image_url) { |_| "http://example.com/img.png" }
    doc
  end
end

require "test_helper"

# Runs the real RubyLLM gem against a stubbed Anthropic endpoint, so these check
# the request body that would go out, not the TestClient double.
class AIBackend::RubyLLM::InterceptedChatTest < ActiveSupport::TestCase
  ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"

  setup do
    WebMock.enable!
    @requests = []
    stub_request(:post, ANTHROPIC_URL).to_return do |request|
      @requests << JSON.parse(request.body)
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          id: "msg_1", type: "message", role: "assistant", model: "claude-opus-5-5",
          content: [
            { type: "thinking", thinking: "Let me work through this...", signature: "sig-abc" },
            { type: "text", text: "The answer is 42." },
          ],
          stop_reason: "end_turn",
          usage: { input_tokens: 10, output_tokens: 20 },
        }.to_json,
      }
    end
  end

  def build_chat(model = "claude-opus-5-5")
    context = RubyLLM.context { |c| c.anthropic_api_key = "test-key" }
    AIBackend::RubyLLM::InterceptedChat.new(model:, provider: :anthropic, assume_model_exists: true, context:)
  end

  test "plain with_thinking is rejected for an assumed model, which is why with_adaptive_thinking exists" do
    chat = build_chat.with_thinking(effort: "high")
    chat.add_message(role: :user, content: "What is 6 x 7?")

    error = assert_raises(ArgumentError) { chat.complete }
    assert_match "not supported", error.message
  end

  test "with_adaptive_thinking sends adaptive thinking with summarized display, the effort and max_tokens" do
    chat = build_chat.with_adaptive_thinking(effort: "high", max_tokens: 16_000)
    chat.add_message(role: :user, content: "What is 6 x 7?")
    response = chat.complete

    body = @requests.sole
    assert_equal({ "type" => "adaptive", "display" => "summarized" }, body["thinking"])
    assert_equal "high", body.dig("output_config", "effort")
    assert_equal 16_000, body["max_tokens"]
    assert_equal "The answer is 42.", response.content
    assert_equal "Let me work through this...", response.thinking.text
    assert_equal "sig-abc", response.thinking.signature
  end

  test "with_adaptive_thinking keeps params that were set before it" do
    chat = build_chat.with_params(metadata: { user_id: "u1" })
    chat.with_adaptive_thinking(effort: "high", max_tokens: 16_000)
    chat.add_message(role: :user, content: "Hi")
    chat.complete

    assert_equal({ "user_id" => "u1" }, @requests.sole["metadata"])
  end

  test "a replayed tool call carries its thinking block, signature included, ahead of the tool_use" do
    chat = build_chat.with_adaptive_thinking(effort: "high", max_tokens: 16_000)
    chat.add_message(role: :user, content: "Weather in Austin?")
    chat.add_message(
      role: :assistant,
      content: "",
      tool_calls: { "call_1" => RubyLLM::ToolCall.new(id: "call_1", name: "get_weather", arguments: { city: "Austin" }) },
      thinking: RubyLLM::Thinking.build(text: "I should look it up.", signature: "sig-tool"),
    )
    chat.add_message(role: :tool, content: "Sunny", tool_call_id: "call_1")
    chat.complete

    assistant = @requests.sole["messages"].find { |m| m["role"] == "assistant" }
    assert_equal({ "type" => "thinking", "thinking" => "I should look it up.", "signature" => "sig-tool" }, assistant["content"].first)
    assert_equal "tool_use", assistant["content"].last["type"]
  end

  test "without with_adaptive_thinking no thinking is requested" do
    chat = build_chat
    chat.add_message(role: :user, content: "Hi")
    chat.complete

    assert_nil @requests.sole["thinking"]
  end
end

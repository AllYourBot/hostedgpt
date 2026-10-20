require "test_helper"

# Runs the real RubyLLM gem against a stubbed Anthropic endpoint, so these check
# the request body that would go out, not the TestClient double.
class AIBackend::RubyLLM::ThinkingConfigurationTest < ActiveSupport::TestCase
  ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"

  setup do
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
    RubyLLM::Chat.new(model:, provider: :anthropic, assume_model_exists: true, context:)
  end

  # 2.0's explicit effort/display never consult the model registry (which has
  # no Claude 5 entries under assume_model_exists), so thinking needs no Model
  # surgery — and the wire payload matches 1.16's adaptive shape.
  test "with_thinking sends adaptive thinking with summarized display, the effort and max_tokens" do
    chat = build_chat.with_thinking(effort: "high", display: "summarized").with_provider_options(max_tokens: 16_000)
    chat.add_message(role: :user, content: "What is 6 x 7?")
    response = chat.generate

    body = @requests.sole
    assert_equal({ "type" => "adaptive", "display" => "summarized" }, body["thinking"])
    assert_equal "high", body.dig("output_config", "effort")
    assert_equal 16_000, body["max_tokens"]
    assert_equal "The answer is 42.", response.content
    assert_equal "Let me work through this...", response.thinking.text
    assert_equal "sig-abc", response.thinking.signature
  end

  test "without with_thinking no thinking is requested" do
    chat = build_chat
    chat.add_message(role: :user, content: "Hi")
    chat.generate

    assert_nil @requests.sole["thinking"]
  end

  test "a replayed tool call carries its thinking block, signature included, ahead of the tool_use" do
    chat = build_chat.with_thinking(effort: "high", display: "summarized").with_provider_options(max_tokens: 16_000)
    chat.add_message(role: :user, content: "Weather in Austin?")
    chat.add_message(
      role: :assistant,
      content: "",
      tool_calls: { "call_1" => RubyLLM::ToolCall.new(id: "call_1", name: "get_weather", arguments: { city: "Austin" }) },
      thinking: RubyLLM::Thinking.build(text: "I should look it up.", signature: "sig-tool"),
    )
    chat.add_message(role: :tool, content: "Sunny", tool_call_id: "call_1")
    chat.generate

    assistant = @requests.sole["messages"].find { |m| m["role"] == "assistant" }
    assert_equal({ "type" => "thinking", "thinking" => "I should look it up.", "signature" => "sig-tool" }, assistant["content"].first)
    assert_equal "tool_use", assistant["content"].last["type"]
  end

  # The deleted 1.16 test pinned the cache_control wire structure; this probe
  # keeps that pin on 2.0's cache_until_here rendering, where a regression
  # would silently drop Anthropic prompt caching.
  test "cache_until_here puts cache_control on the system block" do
    chat = build_chat.with_instructions("You are helpful.", cache_until_here: true)
    chat.add_message(role: :user, content: "What is 6 x 7?")
    chat.generate

    system_blocks = @requests.sole["system"]
    assert_equal({ "type" => "ephemeral" }, system_blocks.last["cache_control"])
  end

  test "without cache_until_here the system block carries no cache_control" do
    chat = build_chat.with_instructions("You are helpful.")
    chat.add_message(role: :user, content: "Hi")
    chat.generate

    refute @requests.sole["system"].last.key?("cache_control")
  end
end

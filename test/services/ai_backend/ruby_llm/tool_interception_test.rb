require "test_helper"

# Runs the real RubyLLM 2.0 gem: `generate` streams and never executes tools,
# so the tool calls arrive on the returned message for the job to run through
# Toolbox.call. The private `provider_completion` stub bypasses only the
# network — a private touchpoint pinned by the ~> 2.0.0 patchlock.
class AIBackend::RubyLLM::ToolInterceptionTest < ActiveSupport::TestCase
  OPENAI_URL = "https://api.openai.com/v1/chat/completions"

  def build_tool
    AIBackend::RubyLLM::ToolSchema.new(
      name: "get_weather",
      description: "Get the current weather for a location",
      parameters_schema: { type: "object", properties: { location: { type: "string" } } }
    )
  end

  def tool_call(id, location)
    RubyLLM::ToolCall.new(id: id, name: "get_weather", arguments: { location: location })
  end

  def build_chat
    chat = RubyLLM::Chat.new(model: "gpt-4o", provider: :openai, assume_model_exists: true)
    chat.add_message(role: :user, content: "What's the weather?")
    chat.with_tools(build_tool)
    chat
  end

  def stub_tool_call_response(chat, tool_calls, &)
    response = RubyLLM::Message.new(
      role: :assistant,
      content: nil,
      tool_calls: tool_calls.to_h { |tc| [tc.id, tc] }
    )
    chat.stub(:provider_completion, response, &)
  end

  test "chat.generate returns the response message carrying the tool calls" do
    chat = build_chat

    response = stub_tool_call_response(chat, [tool_call("call_abc123", "Austin")]) { chat.generate }

    assert response.tool_call?, "the returned message should carry tool calls"
    assert_equal ["call_abc123"], response.tool_calls.values.map(&:id)
    assert_equal ["get_weather"], response.tool_calls.values.map(&:name)
    assert_equal ["Austin"], response.tool_calls.values.map { |tc| tc.arguments[:location] }
  end

  test "every requested tool call is captured, parallel calls included" do
    calls = [tool_call("call_abc123", "Austin"), tool_call("call_def456", "Boston")]
    chat = build_chat

    response = stub_tool_call_response(chat, calls) { chat.generate }

    assert_equal ["call_abc123", "call_def456"], response.tool_calls.values.map(&:id)
    assert_equal ["Austin", "Boston"], response.tool_calls.values.map { |tc| tc.arguments[:location] }
  end

  test "execution halts cleanly: no tool result is appended and the chat does not auto-continue" do
    chat = build_chat

    stub_tool_call_response(chat, [tool_call("call_abc123", "Austin")]) { chat.generate }

    assert_empty chat.messages.select { |m| m.role == :tool },
      "no role: :tool result message should be appended"
    assert_equal 1, chat.messages.count { |m| m.role == :assistant },
      "the chat should not have auto-continued with a follow-up assistant message"
  end

  # The never-execute guarantee must hold for an unregistered/hallucinated name
  # too: Chat#execute_tool answers unknown names with an error hash instead of
  # raising, so only the no-execution property of generate protects here.
  test "generate returns an unregistered tool name untouched instead of auto-executing" do
    chat = build_chat

    hallucinated = RubyLLM::ToolCall.new(id: "call_halluc", name: "not_a_registered_tool", arguments: {})
    response = stub_tool_call_response(chat, [hallucinated]) { chat.generate }

    assert_equal "not_a_registered_tool", response.tool_calls["call_halluc"].name
    assert_empty chat.messages.select { |m| m.role == :tool },
      "no role: :tool result message should be appended for an unregistered tool"
  end

  # The ToolSchema carrier must serialize into the real OpenAI wire payload;
  # this also proves the initializer's Chat Completions protocol pin is live
  # (2.0 defaults OpenAI to the Responses API, whose endpoint differs).
  test "ToolSchema renders its name, description, and parameters into the request payload" do
    @requests = []
    stub_request(:post, OPENAI_URL).to_return do |request|
      @requests << JSON.parse(request.body)
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { id: "chatcmpl-1", object: "chat.completion", model: "gpt-4o",
          choices: [ { index: 0, message: { role: "assistant", content: "Sure." }, finish_reason: "stop" } ],
        }.to_json,
      }
    end

    context = RubyLLM.context { |c| c.openai_api_key = "test-key" }
    chat = RubyLLM::Chat.new(model: "gpt-4o", provider: :openai, assume_model_exists: true, context:)
    chat.add_message(role: :user, content: "What's the weather?")
    chat.with_tools(build_tool)
    chat.generate

    body = @requests.sole
    tool_payload = body["tools"].sole
    assert_equal "function", tool_payload["type"]
    assert_equal "get_weather", tool_payload.dig("function", "name")
    assert_equal "Get the current weather for a location", tool_payload.dig("function", "description")
    assert_equal({ "type" => "object", "properties" => { "location" => { "type" => "string" } } },
      tool_payload.dig("function", "parameters"))
  end
end

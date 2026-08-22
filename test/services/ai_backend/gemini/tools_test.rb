require "test_helper"

class AIBackend::Gemini::ToolsTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:gemini_conversation)
    @gemini = AIBackend::Gemini.new(
      users(:keith),
      assistants(:keith_gemini),
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    TestClient::Gemini.new(access_token: "abc")
  end

  test "gemini_format_tools nests all functions inside a single function_declarations entry" do
    openai_tools = [
      {
        type: "function",
        function: {
          name: "helloworld_hi",
          description: "Says hi",
          parameters: { type: "object", properties: { "name" => { type: "string" } }, required: ["name"] }
        }
      },
      {
        type: "function",
        function: {
          name: "memory_remember_detail_about_user",
          description: "Remembers",
          parameters: { type: "object", properties: { "detail" => { type: "string" } }, required: ["detail"] }
        }
      }
    ]

    result = @gemini.send(:gemini_format_tools, openai_tools)

    assert_equal 1, result.length
    declarations = result[0][:function_declarations]
    assert_equal 2, declarations.length
    assert_equal "helloworld_hi", declarations[0][:name]
    assert_equal "Says hi", declarations[0][:description]
    assert_equal({ "name" => { type: "string" } }, declarations[0][:parameters][:properties])
    assert_equal ["name"], declarations[0][:parameters][:required]
  end

  test "gemini_format_tools omits the parameters schema when a function takes no arguments" do
    openai_tools = [
      { type: "function", function: { name: "clock_now", description: "Time", parameters: { type: "object", properties: {}, required: [] } } }
    ]

    declaration = @gemini.send(:gemini_format_tools, openai_tools).dig(0, :function_declarations, 0)

    assert_equal "clock_now", declaration[:name]
    refute declaration.key?(:parameters), "Gemini rejects an empty object schema, so parameters should be omitted"
  end

  test "gemini_format_tools returns nil when there are no tools" do
    assert_nil @gemini.send(:gemini_format_tools, [])
    assert_nil @gemini.send(:gemini_format_tools, nil)
  end

  test "format_parallel_tool_calls converts Gemini functionCall parts to OpenAI format" do
    parts = [
      { "functionCall" => { "name" => "image_generate_an_image", "args" => { "image_generation_prompt_s" => "A cat" } } }
    ]

    result = @gemini.send(:format_parallel_tool_calls, parts)

    assert_equal 1, result.length
    assert_equal 0, result[0][:index]
    assert_equal "function", result[0][:type]
    assert_equal "call_0_image_generate_an_image", result[0][:id]
    assert_equal "image_generate_an_image", result[0][:function][:name]
    assert_equal '{"image_generation_prompt_s":"A cat"}', result[0][:function][:arguments]
    refute result[0].key?(:thought_signature), "No signature was offered, so none should be recorded"
  end

  test "format_parallel_tool_calls keeps the thoughtSignature Gemini attached to the part" do
    parts = [
      { "functionCall" => { "name" => "helloworld_hi", "args" => { "name" => "Keith" } }, "thoughtSignature" => "sig-abc" }
    ]

    result = @gemini.send(:format_parallel_tool_calls, parts)

    assert_equal "sig-abc", result[0][:thought_signature]
  end

  test "format_parallel_tool_calls assigns a distinct id to each of several calls and only the first carries a signature" do
    parts = [
      { "functionCall" => { "name" => "helloworld_hi", "args" => { "name" => "Keith" } }, "thoughtSignature" => "sig-abc" },
      { "functionCall" => { "name" => "helloworld_hi", "args" => { "name" => "Rob" } } }
    ]

    result = @gemini.send(:format_parallel_tool_calls, parts)

    assert_equal 2, result.length
    assert_equal [0, 1], result.map { |c| c[:index] }
    assert_equal result.map { |c| c[:id] }.uniq.length, result.length
    assert_equal "sig-abc", result[0][:thought_signature]
    refute result[1].key?(:thought_signature), "Gemini only signs the first of a parallel batch"
  end

  test "format_parallel_tool_calls prefers an id supplied by the API" do
    result = @gemini.send(:format_parallel_tool_calls, [{ "functionCall" => { "id" => "abc123", "name" => "helloworld_hi", "args" => {} } }])

    assert_equal "abc123", result[0][:id]
  end

  test "format_parallel_tool_calls skips malformed parts" do
    result = @gemini.send(:format_parallel_tool_calls, [nil, { "functionCall" => { "args" => { "a" => 1 } } }, { "text" => "hi" }, "junk"])

    assert_equal [], result
  end

  test "format_parallel_tool_calls returns an empty array when there were no calls" do
    assert_equal [], @gemini.send(:format_parallel_tool_calls, [])
    assert_equal [], @gemini.send(:format_parallel_tool_calls, nil)
  end
end

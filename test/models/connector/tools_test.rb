require "test_helper"

class Connector::ToolsTest < ActiveSupport::TestCase
  setup do
    @connector = connectors(:github)
  end

  test "save_with_tools SAVES the tools the server lists" do
    connector = users(:keith).connectors.new(name: "Calendar", url: "https://mcp.example.com/calendar")
    stub_mcp_server(connector.url, tools: [{ name: "list_events", description: "List events", inputSchema: { type: "object" } }])

    assert connector.save_with_tools, "The connector should save once the server answers"
    assert_equal ["list_events"], connector.reload.tool_names, "The listed tools should be stored"
  end

  test "save_with_tools REFRESHES the tools and drops disabled names the server no longer lists" do
    stub_mcp_server(@connector.url, tools: [{ name: "search_issues" }, { name: "list_pull_requests" }])

    assert @connector.save_with_tools
    @connector.reload
    assert_equal ["search_issues", "list_pull_requests"], @connector.tool_names, "The tools should match what the server lists now"
    assert_empty @connector.disabled_tool_names, "create_issue is gone from the server, so it shouldn't stay disabled"
    assert_equal ["search_issues", "list_pull_requests"], @connector.enabled_tool_names, "A tool the server added should start out enabled"
  end

  test "save_with_tools does NOT SAVE when the server can't be reached" do
    connector = users(:keith).connectors.new(name: "Calendar", url: "https://mcp.example.com/calendar")
    stub_request(:post, connector.url).to_return(status: 401)

    assert_no_difference "Connector.count" do
      refute connector.save_with_tools, "A connector the server won't answer for should not be saved"
    end
    assert_equal ["Couldn't load the tools: The server answered with HTTP 401 (check the token)"], connector.errors[:base]
  end

  test "save_with_tools does NOT CONTACT the server when the connector is invalid" do
    connector = users(:keith).connectors.new(name: "", url: "https://mcp.example.com/calendar")

    refute connector.save_with_tools
    assert_equal ["can't be blank"], connector.errors[:name]
    assert_not_requested :post, connector.url
  end

  test "enabled_tools LEAVES OUT the disabled tools" do
    assert_equal ["search_issues"], @connector.enabled_tools.map { it["name"] }
    assert_equal ["search_issues"], @connector.enabled_tool_names
  end

  test "enabled_tool_names= DISABLES every tool left unchecked" do
    @connector.enabled_tool_names = ["", "create_issue"]
    assert_equal ["search_issues"], @connector.disabled_tool_names, "The unchecked tool should be disabled"

    @connector.enabled_tool_names = [""]
    assert_equal ["search_issues", "create_issue"], @connector.disabled_tool_names, "Unchecking everything should disable every tool"
  end

  test "ruby_llm_tools returns a tool for each ENABLED tool" do
    tools = @connector.ruby_llm_tools

    assert_equal ["connector#{@connector.id}_search_issues"], tools.map(&:name), "Only the enabled tool should be offered"
    assert tools.all? { it.is_a?(Toolbox::ConnectorTool) }
  end

  test "function_name REPLACES characters providers reject and keeps within 64 characters" do
    assert_equal "connector#{@connector.id}_files_read-text", @connector.function_name("files.read-text")
    assert_equal 64, @connector.function_name("a" * 100).length, "Providers reject tool names over 64 characters"
  end

  test "call_tool CALLS the tool on the server with the connector's token" do
    stub_mcp_server(@connector.url, call_result: { content: [{ type: "text", text: "3 issues" }] })

    result = @connector.call_tool("search_issues", { query: "bug" })

    assert_equal "3 issues", result.dig("content", 0, "text")
    assert_requested :post, @connector.url, body: hash_including("method" => "tools/call"), headers: { "Authorization" => "Bearer ghp-secret" }
  end
end

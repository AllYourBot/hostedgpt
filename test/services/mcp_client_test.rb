require "test_helper"

class MCPClientTest < ActiveSupport::TestCase
  URL = "https://mcp.example.com/mcp"

  test "tools OPENS a session and then lists the server's tools" do
    stub = stub_mcp_server(URL, tools: [{ name: "search_issues", inputSchema: { type: "object" } }])

    tools = MCPClient.new(url: URL).tools

    assert_equal ["search_issues"], tools.map { it["name"] }, "The server's tools should come back as it listed them"
    assert_requested stub, times: 3 # initialize, notifications/initialized, tools/list
    assert_requested :post, URL, times: 1, body: hash_including("method" => "initialize", "params" => hash_including("protocolVersion" => MCPClient::PROTOCOL_VERSION))
    assert_requested :post, URL, times: 1, body: hash_including("method" => "notifications/initialized")
  end

  test "tools SENDS the token, the session id and the protocol version once the session is open" do
    stub_mcp_server(URL, tools: [])

    MCPClient.new(url: URL, token: "ghp-secret").tools

    assert_requested :post, URL, times: 3, headers: { "Authorization" => "Bearer ghp-secret", "Accept" => "application/json, text/event-stream" }
    assert_requested :post, URL, times: 1, body: hash_including("method" => "tools/list"),
      headers: { "Mcp-Session-Id" => "session-1", "MCP-Protocol-Version" => MCPClient::PROTOCOL_VERSION }
  end

  test "tools sends NO authorization header without a token" do
    stub_mcp_server(URL, tools: [])

    MCPClient.new(url: URL, token: "").tools

    assert_not_requested :post, URL, headers: { "Authorization" => /.*/ }
  end

  test "tools FOLLOWS nextCursor through every page" do
    stub_request(:post, URL).to_return do |request|
      rpc = JSON.parse(request.body)
      next { status: 202 } unless rpc.key?("id")

      result = case [rpc["method"], rpc.dig("params", "cursor")]
      in ["initialize", _] then { protocolVersion: MCPClient::PROTOCOL_VERSION }
      in ["tools/list", nil] then { tools: [{ name: "first" }], nextCursor: "page-2" }
      in ["tools/list", "page-2"] then { tools: [{ name: "second" }] }
      end
      { status: 200, headers: { "Content-Type" => "application/json" }, body: { jsonrpc: "2.0", id: rpc["id"], result: }.to_json }
    end

    assert_equal ["first", "second"], MCPClient.new(url: URL).tools.map { it["name"] }, "Tools from every page should be returned"
  end

  test "tools READS a response sent as an event stream, skipping the messages ahead of it" do
    stub_request(:post, URL).to_return do |request|
      rpc = JSON.parse(request.body)
      next { status: 202 } unless rpc.key?("id")

      result = rpc["method"] == "initialize" ? { protocolVersion: MCPClient::PROTOCOL_VERSION } : { tools: [{ name: "streamed" }] }
      progress = { jsonrpc: "2.0", method: "notifications/progress", params: { progress: 1 } }
      body = "event: message\ndata: #{progress.to_json}\n\nevent: message\ndata: #{{ jsonrpc: "2.0", id: rpc["id"], result: }.to_json}\n\n"
      { status: 200, headers: { "Content-Type" => "text/event-stream" }, body: }
    end

    assert_equal ["streamed"], MCPClient.new(url: URL).tools.map { it["name"] }, "The response should be found in the stream"
  end

  test "call_tool RETURNS the server's result for the tool" do
    stub_mcp_server(URL, call_result: { content: [{ type: "text", text: "3 issues" }], isError: false })

    result = MCPClient.new(url: URL).call_tool("search_issues", { query: "bug" })

    assert_equal [{ "type" => "text", "text" => "3 issues" }], result["content"], "The tool's content should come back"
    assert_requested :post, URL, times: 1, body: hash_including("method" => "tools/call", "params" => { "name" => "search_issues", "arguments" => { "query" => "bug" } })
  end

  test "RAISES with the server's message when it answers with a JSON-RPC error" do
    stub_request(:post, URL).to_return do |request|
      rpc = JSON.parse(request.body)
      { status: 200, headers: { "Content-Type" => "application/json" }, body: { jsonrpc: "2.0", id: rpc["id"], error: { code: -32602, message: "Unknown tool" } }.to_json }
    end

    error = assert_raises(MCPClient::Error) { MCPClient.new(url: URL).tools }
    assert_equal "initialize failed: Unknown tool", error.message, "The server's own error message should be passed on"
  end

  test "RAISES and suggests checking the token when the server answers 401" do
    stub_request(:post, URL).to_return(status: 401)

    error = assert_raises(MCPClient::Error) { MCPClient.new(url: URL, token: "wrong").tools }
    assert_equal "The server answered with HTTP 401 (check the token)", error.message
  end

  test "RAISES when the server can't be reached" do
    stub_request(:post, URL).to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    error = assert_raises(MCPClient::Error) { MCPClient.new(url: URL).tools }
    assert_equal "Could not reach the server: Connection refused", error.message
  end

  test "RAISES when the server answers with something other than JSON" do
    stub_request(:post, URL).to_return(status: 200, headers: { "Content-Type" => "text/html" }, body: "<html>Not an MCP server</html>")

    error = assert_raises(MCPClient::Error) { MCPClient.new(url: URL).tools }
    assert_equal "The server sent a response that isn't JSON", error.message
  end
end

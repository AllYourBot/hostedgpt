module MCPServerHelper
  private

  # Stubs a Streamable HTTP MCP server at url: it opens a session, lists tools, and answers every
  # tools/call with call_result. Returns the WebMock stub so a test can assert on the requests.
  def stub_mcp_server(url, tools: [], call_result: {})
    stub_request(:post, url).to_return do |request|
      rpc = JSON.parse(request.body)
      next { status: 202 } unless rpc.key?("id") # a notification gets no answer

      result = case rpc["method"]
      when "initialize" then { protocolVersion: MCPClient::PROTOCOL_VERSION, capabilities: { tools: {} }, serverInfo: { name: "test", version: "1" } }
      when "tools/list" then { tools: }
      when "tools/call" then call_result
      end

      {
        status: 200,
        headers: { "Content-Type" => "application/json", "Mcp-Session-Id" => "session-1" },
        body: { jsonrpc: "2.0", id: rpc["id"], result: }.to_json,
      }
    end
  end
end

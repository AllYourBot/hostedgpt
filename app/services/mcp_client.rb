# A minimal client for a remote MCP (Model Context Protocol) server over the
# Streamable HTTP transport: JSON-RPC requests POSTed to one URL, answered with
# either a JSON body or a server-sent event stream. Each instance opens its own
# session on the first request (initialize, then notifications/initialized).
class MCPClient
  class Error < StandardError; end

  PROTOCOL_VERSION = "2025-06-18"

  def initialize(url:, token: nil)
    @url = url
    @token = token
  end

  # Every tool the server offers, following nextCursor through each page.
  def tools
    tools = []
    cursor = nil
    loop do
      result = request("tools/list", cursor ? { cursor: } : {})
      tools += Array(result["tools"])
      break if (cursor = result["nextCursor"]).blank?
    end
    tools
  end

  # The raw CallToolResult: content blocks, maybe structuredContent, and isError.
  def call_tool(name, arguments) = request("tools/call", { name:, arguments: })

  private

  def request(method, params)
    open_session unless @protocol_version
    rpc(method, params)
  end

  def open_session
    result = rpc("initialize", {
      protocolVersion: PROTOCOL_VERSION,
      capabilities: {},
      clientInfo: { name: Setting.product_name, version: "1.0" },
    })
    @protocol_version = result["protocolVersion"].presence || PROTOCOL_VERSION
    post({ jsonrpc: "2.0", method: "notifications/initialized" })
  end

  def rpc(method, params)
    id = @last_id = @last_id.to_i + 1
    response = post({ jsonrpc: "2.0", id:, method:, params: })
    message = response_message(response, id)

    raise Error, "#{method} failed: #{message.dig("error", "message") || message["error"]}" if message["error"]
    message["result"] || {}
  end

  def post(body)
    response = connection.post { it.body = body.to_json }
    @session_id = response.headers["mcp-session-id"] if response.headers["mcp-session-id"].present?
    return response if response.success?

    hint = " (check the token)" if response.status.in?([401, 403])
    raise Error, "The server answered with HTTP #{response.status}#{hint}"
  rescue Faraday::Error => e
    raise Error, "Could not reach the server: #{e.message}"
  end

  def connection
    Faraday.new(url: @url, headers:, request: { open_timeout: 10, timeout: 60 })
  end

  def headers
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json, text/event-stream",
      "Authorization" => ("Bearer #{@token}" if @token.present?),
      "Mcp-Session-Id" => @session_id,
      "MCP-Protocol-Version" => @protocol_version,
    }.compact
  end

  # A stream can carry notifications or requests ahead of the response, so pick out the message answering id.
  def response_message(response, id)
    messages = if response.headers["content-type"].to_s.include?("text/event-stream")
      sse_messages(response.body)
    else
      Array.wrap(parse(response.body))
    end

    messages.find { it.is_a?(Hash) && it["id"] == id && (it.key?("result") || it.key?("error")) } ||
      raise(Error, "The server sent no response to the request")
  end

  def sse_messages(body)
    body.to_s.split(/\r?\n\r?\n/).filter_map do |event|
      data = event.lines.select { it.start_with?("data:") }.map { it.delete_prefix("data:").strip }.join("\n")
      parse(data) if data.present?
    end
  end

  def parse(json)
    JSON.parse(json)
  rescue JSON::ParserError
    raise Error, "The server sent a response that isn't JSON"
  end
end

# One tool from a connector's MCP server as a RubyLLM::Tool. The model sees the
# server's own description and input schema (less the $schema dialect marker,
# which some providers reject); execute forwards the arguments to the server as
# they came, and errors are reported the way every Toolbox tool reports them.
class Toolbox::ConnectorTool < Toolbox::RubyLLMTool
  def initialize(connector, tool)
    @connector = connector
    @tool_name = tool["name"]
    super({
      function: {
        name: connector.function_name(@tool_name),
        description: tool["description"].presence || tool["title"].presence || @tool_name,
        parameters: tool["inputSchema"].presence&.except("$schema") || { "type" => "object", "properties" => {} },
      }
    })
  end

  private

  def result_for(arguments)
    result = @connector.call_tool(@tool_name, arguments)

    {
      message_to_user: "#{@connector.name}: #{@tool_name}",
      (result["isError"] ? :error : :result) => text_of(result),
    }
  end

  def text_of(result)
    texts = Array(result["content"]).map do |block|
      case block["type"]
      when "text" then block["text"]
      when "resource" then block.dig("resource", "text") || block.dig("resource", "uri")
      when "resource_link" then "#{block["name"]} (#{block["uri"]})"
      else "[#{block["type"]} content]"
      end
    end

    texts.compact.presence&.join("\n\n") || result["structuredContent"]&.to_json.to_s
  end
end

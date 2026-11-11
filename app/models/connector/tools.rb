module Connector::Tools
  extend ActiveSupport::Concern

  # Lists the server's tools before saving, so a connector the server won't answer for is never kept
  # and the tools offered to assistants are the ones the server has now.
  def save_with_tools
    return false unless valid?

    self.tools = client.tools
    self.disabled_tool_names &= tool_names
    save
  rescue MCPClient::Error => e
    errors.add(:base, "Couldn't load the tools: #{e.message}")
    false
  end

  def tool_names = tools.map { it["name"] }

  def enabled_tools = tools.reject { it["name"].in?(disabled_tool_names) }

  def enabled_tool_names = tool_names - disabled_tool_names

  # The form checks the tools to keep, so a tool the server adds later starts out enabled.
  def enabled_tool_names=(names)
    self.disabled_tool_names = tool_names - Array(names).compact_blank
  end

  def ruby_llm_tools = enabled_tools.map { Toolbox::ConnectorTool.new(self, it) }

  # The id keeps two connectors, or a connector and a Toolbox tool, from sharing a name. Providers
  # accept only letters, digits, _ and - in a tool name, at most 64 of them.
  def function_name(tool_name) = "connector#{id}_#{tool_name.gsub(/[^a-zA-Z0-9_-]/, "_")}".first(64)

  def call_tool(tool_name, arguments) = client.call_tool(tool_name, arguments)

  private

  def client = MCPClient.new(url:, token:)
end

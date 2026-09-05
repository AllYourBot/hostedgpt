# Intercepts RubyLLM's automatic tool-execution loop by raising from `execute`.
# HostedGPT executes tools itself via Toolbox.call (see Phase 5), so RubyLLM
# must never run a tool or auto-continue the conversation after a tool-call
# response. Raising here halts Chat#handle_tool_calls before it can append a
# role: :tool result message; the assistant's tool-call message is already on
# chat.messages by the time this runs (verified against ruby_llm-1.16.0).
class AIBackend::RubyLLM::InterceptedTool < ::RubyLLM::Tool
  def initialize(name:, description:, params_schema:)
    @tool_name = name
    @tool_description = description
    @params_schema = params_schema
  end

  # Overrides are required: the base class otherwise derives `name` from the
  # class name, collapsing every registered tool into one garbage entry.
  def name
    @tool_name
  end

  def description
    @tool_description
  end

  def execute(**)
    raise AIBackend::RubyLLM::ToolCallIntercepted
  end
end

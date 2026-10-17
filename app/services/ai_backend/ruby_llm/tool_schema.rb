# The tool carrier for RubyLLM 2.0: exposes the Toolbox's OpenAI-shaped tool
# descriptors through ::RubyLLM::Tool's readers (2.0's `parameters_schema`;
# 1.16's `params_schema` is gone) so the model sees the schemas. HostedGPT
# executes tools itself via Toolbox.call (see GetNextAIMessageJob), and the
# backend reads tool calls from the message `generate` returns — which never
# executes tools — so `execute` is unreachable; it raises as a tripwire.
class AIBackend::RubyLLM::ToolSchema < ::RubyLLM::Tool
  def initialize(name:, description:, parameters_schema:)
    @name = name
    @description = description
    @parameters_schema = parameters_schema
  end

  # Overrides are required: the base class otherwise derives `name` from the
  # class name, collapsing every registered tool into one garbage entry.
  def name
    @name
  end

  def description
    @description
  end

  def execute(**)
    raise NotImplementedError, "HostedGPT executes tools via Toolbox.call, never through RubyLLM"
  end
end

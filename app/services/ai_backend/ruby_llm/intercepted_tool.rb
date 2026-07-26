# frozen_string_literal: true

class AIBackend::RubyLLM::InterceptedTool < ::RubyLLM::Tool
  def initialize(name:, description:, params_schema:)
    @tool_name = name
    @tool_description = description
    @params_schema = params_schema
  end

  def name
    @tool_name
  end

  def description
    @tool_description
  end

  def execute(**)
    raise "InterceptedTool.execute should never be called — InterceptedChat prevents tool execution"
  end
end

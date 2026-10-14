# Overrides RubyLLM::Chat#handle_tool_calls (private) so any tool call the model
# requests — registered or hallucinated — raises ToolCallIntercepted before
# RubyLLM can auto-execute it or recurse. Without this, an unknown tool name is
# answered by Chat#execute_tool with an error hash (no raise), which appends an
# internal role: :tool result and auto-continues, silently dropping the call and
# risking unbounded recursion. This couples to a private method, but the gem is
# pinlocked to ~> 1.16.0; InterceptedTool#execute remains as a safety net so a
# registered-name call still halts even if this override is renamed upstream.
class AIBackend::RubyLLM::InterceptedChat < ::RubyLLM::Chat
  # Anthropic adaptive thinking for a model whose LanguageModel says it can think.
  #
  # Chats are built with assume_model_exists, so the model is Model::Info.default,
  # which declares no reasoning options, and with_thinking would raise "Anthropic
  # thinking effort is not supported" (RubyLLM 1.16's registry has no Claude 5
  # model at all). LanguageModel#supports_thinking is the source of truth here,
  # so the effort option is declared on the model before thinking is enabled.
  #
  # display: "summarized" opts in to readable thinking: on Claude Opus 4.7 and
  # later it defaults to "omitted", which streams an empty thinking field with
  # only the signature. RubyLLM deep-merges params into the request body.
  def with_adaptive_thinking(effort:, max_tokens:)
    unless @model.reasoning_option("effort")
      @model = ::RubyLLM::Model::Info.new(@model.to_h.merge(reasoning_options: [{ type: "effort" }]))
    end

    with_thinking(effort:)
    with_params(**params, max_tokens:, thinking: { display: "summarized" })
  end

  private

  def handle_tool_calls(_response, &)
    raise AIBackend::RubyLLM::ToolCallIntercepted
  end
end

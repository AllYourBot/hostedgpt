# Overrides RubyLLM::Chat#handle_tool_calls (private) so any tool call the model
# requests — registered or hallucinated — raises ToolCallIntercepted before
# RubyLLM can auto-execute it or recurse. Without this, an unknown tool name is
# answered by Chat#execute_tool with an error hash (no raise), which appends an
# internal role: :tool result and auto-continues, silently dropping the call and
# risking unbounded recursion. This couples to a private method, but the gem is
# pinlocked to ~> 1.16.0; InterceptedTool#execute remains as a safety net so a
# registered-name call still halts even if this override is renamed upstream.
class AIBackend::RubyLLM::InterceptedChat < ::RubyLLM::Chat
  private

  def handle_tool_calls(_response, &)
    raise AIBackend::RubyLLM::ToolCallIntercepted
  end
end

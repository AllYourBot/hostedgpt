# frozen_string_literal: true

# Overrides RubyLLM::Chat#handle_tool_calls (private) to prevent automatic
# tool execution. This couples to RubyLLM's internal API — the gem is pinned
# to ~> 1.16 in the Gemfile. If handle_tool_calls is renamed or removed in a
# future version, InterceptedTool#execute will raise as a safety net.
class AIBackend::RubyLLM::InterceptedChat < ::RubyLLM::Chat
  private

  # HostedGPT handles tool execution itself via Toolbox.call, so we never want
  # RubyLLM to execute tools or continue the conversation after a tool-call
  # response. Returning the response lets the backend extract the tool_calls
  # and hand them off to GetNextAIMessageJob.
  def handle_tool_calls(response, &)
    response
  end
end

module AIBackend::Anthropic::Tools
  extend ActiveSupport::Concern

  included do
    private

    def format_parallel_tool_calls(content_tool_calls)
      []
    end
  end
end

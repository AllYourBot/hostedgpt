module AIBackend::Anthropic::Tools
  extend ActiveSupport::Concern

  included do
    private

    def format_parallel_tool_calls(content_tool_calls)
<<<<<<< HEAD
      return [] if content_tool_calls.blank?

      # Convert from Anthropic's format to internal OpenAI-compatible format
      content_tool_calls.compact.map.with_index do |tool_call, index|
        if tool_call.nil? || !tool_call.is_a?(Hash)
          next
        end

        unless tool_call["name"].present?
          next
        end

=======
      # Convert Anthropic tool_use format to OpenAI-compatible format
      content_tool_calls.map do |tool_use|
>>>>>>> a685f76 (WIP: claude image gen)
        {
          index: index,
          type: "function",
          id: tool_call["id"] || "tool_#{index}",
          function: {
            name: tool_call["name"],
            arguments: (tool_call["input"] || {}).to_json
          }
        }
      end.compact
    rescue => e
      Rails.logger.info "Error formatting Anthropic tool calls: #{e.message}"
      []
    end
  end
end

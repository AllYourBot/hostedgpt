module AIBackend::Anthropic::Tools
  extend ActiveSupport::Concern

  included do
    private

    def format_parallel_tool_calls(content_tool_calls)
      return [] if content_tool_calls.blank?

      # Anthropic returns tool_use blocks in a different format than OpenAI
      # Convert from Anthropic's format to internal OpenAI-compatible format
      content_tool_calls.compact.map.with_index do |tool_call, index|
        # Skip if tool_call is nil or malformed
        if tool_call.nil? || !tool_call.is_a?(Hash)
          Rails.logger.error "#### Skipping nil or invalid tool_call at index #{index}: #{tool_call.inspect}"
          next
        end

         # Ensure required fields exist
        unless tool_call["name"].present?
          Rails.logger.error "#### Skipping tool_call with missing name at index #{index}: #{tool_call.inspect}"
          next
        end

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

module AIBackend::Gemini::Tools
  extend ActiveSupport::Concern

  included do
    private

    # Gemini declares tools as a single entry containing every function, and it
    # rejects a parameters schema that has no properties, so those are omitted.
    def gemini_format_tools(openai_tools)
      return nil if openai_tools.blank?

      declarations = openai_tools.map do |tool|
        function = tool[:function]
        properties = function.dig(:parameters, :properties) || {}

        {
          name: function[:name],
          description: function[:description],
          parameters: (properties.present? ? {
            type: function.dig(:parameters, :type) || "object",
            properties: properties,
            required: function.dig(:parameters, :required) || []
          } : nil)
        }.compact
      end

      [{ function_declarations: declarations }]
    rescue => e
      Rails.logger.info "Error formatting tools for Gemini: #{e.message}"
      nil
    end

    # Convert from Gemini's functionCall parts to the internal OpenAI-compatible
    # format. Gemini doesn't return an id for a call, so we synthesize one. The
    # thoughtSignature that Gemini 3 attaches to the part is carried along
    # because it has to be echoed back on the next request.
    def format_parallel_tool_calls(parts)
      return [] if parts.blank?

      parts.compact.map.with_index do |part, index|
        next unless part.is_a?(Hash)

        function_call = part["functionCall"] || part[:functionCall]
        next if function_call.blank?

        name = function_call["name"] || function_call[:name]
        next if name.blank?

        args = function_call["args"] || function_call[:args] || {}

        {
          index: index,
          type: "function",
          id: function_call["id"] || function_call[:id] || "call_#{index}_#{name}"[0...40],
          thought_signature: part["thoughtSignature"] || part[:thoughtSignature],
          function: {
            name: name,
            arguments: args.to_json
          }
        }.compact
      end.compact
    rescue => e
      Rails.logger.info "Error formatting Gemini tool calls: #{e.message}"
      []
    end
  end
end

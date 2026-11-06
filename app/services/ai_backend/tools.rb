module AIBackend::Tools
  extend ActiveSupport::Concern

  class_methods do
    # RubyLLM runs the calls (Chat#run_tools); the job then persists one message
    # per result and asks the model for its follow-up. The chat only runs local
    # tools here and never sends a request, so its model and key are placeholders.
    def get_tool_messages_by_calling(tool_calls_response)
      tool_calls = deep_json_parse(tool_calls_response)

      chat = ::RubyLLM::Chat.new(model: "hostedgpt-tool-runner", provider: :openai, assume_model_exists: true,
        context: ::RubyLLM.context { it.openai_api_key = "unused" })
      chat.with_tools(*Toolbox.ruby_llm_tools)
      chat.add_message(role: :assistant, content: "", tool_calls: tool_calls.to_h { [it[:id], ruby_llm_tool_call(it)] })
      chat.run_tools

      results = chat.messages.select(&:tool_result?).index_by(&:tool_call_id)
      tool_calls.map do |tool_call|
        { role: "tool", content: results.fetch(tool_call[:id]).content, content_tool_calls: tool_call, tool_call_id: tool_call[:id] }
      end
    rescue => e
      Rails.logger.info "## UNHANDLED error calling tools: #{e.message}"
      Rails.logger.info e.backtrace.join("\n")
      raise ::Faraday::ParsingError
    end

    private

    def ruby_llm_tool_call(tool_call)
      name = tool_call.dig(:function, :name)
      arguments = tool_call.dig(:function, :arguments)
      raise "Unexpected tool call: #{tool_call[:id]}, #{name}, and #{arguments}" if name.blank? || arguments.nil?

      arguments = JSON.parse(arguments) if arguments.is_a?(String)
      ::RubyLLM::ToolCall.new(id: tool_call[:id], name:, arguments: arguments.to_h)
    end
  end
end

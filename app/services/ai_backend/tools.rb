module AIBackend::Tools
  extend ActiveSupport::Concern

  class_methods do
    def get_tool_messages_by_calling(tool_calls_response)
      tool_calls = deep_json_parse(tool_calls_response)

      # We could parallelize function calling using ruby threads
      tool_calls.map do |tool_call|
        id = tool_call.dig(:id)
        function_name = tool_call.dig(:function, :name)
        function_arguments = tool_call.dig(:function, :arguments)

        raise "Unexpected tool call: #{id}, #{function_name}, and #{function_arguments}" if function_name.blank? || function_arguments.nil?

        function_response = begin
          Toolbox.call(function_name, function_arguments)
        rescue => e
          Rails.logger.info "## Handled error calling tools: #{e.message}" unless Rails.env.test?
          Rails.logger.info e.backtrace.join("\n") unless Rails.env.test?

          <<~STR.gsub("\n", " ")
            An unexpected error occurred (#{e.message}). You were querying information to help you answer a users question. Because this information
            is not available at this time, DO NOT MAKE ANY GUESSES as you attempt to answer the users questions. Instead, consider attempting a
            different query OR let the user know you attempted to retrieve some information but the website is having difficulties at this time.
          STR
        end

        {
          role: "tool",
          content: function_response.to_json,
          tool_call_id: id,
        }
      end
    rescue => e
      Rails.logger.info "## UNHANDLED error calling tools: #{e.message}"
      Rails.logger.info e.backtrace.join("\n")
      raise ::Faraday::ParsingError
    end
  end

  included do
    private

    def format_parallel_tool_calls(content_tool_calls)
      raise NotImplementedError
    end

    def parallel_tool_calls(content_tool_calls)
      raise NotImplementedError
    end
  end
end

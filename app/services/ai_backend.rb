class AIBackend
  attr :client

  def initialize(user, assistant, conversation, message)
    @user = user
    @assistant = assistant
    @conversation = conversation
    @message = message
  end

  def self.get_tool_messages_by_calling(tool_calls_response)
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
        puts "## Handled error calling tools: #{e.message}" unless Rails.env.test?
        puts e.backtrace.join("\n") unless Rails.env.test?

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
    puts "## UNHANDLED error calling tools: #{e.message}"
    puts e.backtrace.join("\n")
    raise ::Faraday::ParsingError
  end

  private

  def full_instructions
    s = @assistant.instructions.to_s

    if @user.memories.present?
      s += "\n\nNote these additional items that you've been told and remembered:\n\n"
      s += @user.memories.pluck(:detail).join("\n")
    end

    s += "\n\nThe current time & date for the user is {{ " + DateTime.current.strftime("%-l:%M%P on %A, %B %-d, %Y") + " }}"
    s.strip
  end

  def deep_streaming_merge(hash1, hash2)
    merged_hash = hash1.dup
    hash2.each do |key, value|
      if merged_hash.has_key?(key) && merged_hash[key].is_a?(Hash) && value.is_a?(Hash)
        merged_hash[key] = deep_streaming_merge(merged_hash[key], value)
      elsif merged_hash.has_key?(key)
        merged_hash[key] += value
      else
        merged_hash[key] = value
      end
    end
    merged_hash
  end

  def self.deep_json_parse(obj)
    if obj.is_a?(Array)
      obj.map { |item| deep_json_parse(item) }
    else
      converted_hash = {}
      obj.each do |key, value|
        if value.is_a?(Hash)
          converted_hash[key] = deep_json_parse(value)
        else
          converted_hash[key] = begin
            JSON.parse(value)
          rescue => e
            value
          end
        end
      end
      converted_hash
    end
  end
end

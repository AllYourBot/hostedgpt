module AIBackend::OpenAI::Tools
  extend ActiveSupport::Concern

  included do
    private

    def format_parallel_tool_calls(content_tool_calls)
      if content_tool_calls.length > 1 || (calls = content_tool_calls.dig(0, "id"))&.scan("call_").length == 1
        return content_tool_calls
      end

      names = find_repeats_and_split(content_tool_calls.dig(0, "function", "name"))
      args = content_tool_calls.dig(0, "function", "arguments").split(/(?<=})(?={)/)

      calls.split(/(?=call_)/).map.with_index do |id, i|
        {
          index: i,
          type: "function",
          id: id[0...40],
          function: {
            name: names.fetch(i),
            arguments: args.fetch(i),
          }
        }
      end
    rescue
      []
    end
  end
end

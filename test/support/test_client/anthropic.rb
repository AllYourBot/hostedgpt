module TestClient
  class Anthropic
    attr_reader :uri_base
    def initialize(access_token:, uri_base:nil)
      @uri_base = uri_base
    end

    def self.text
      nil
    end

    def self.function
      raise "Attempting to return a function response but .function method is not stubbed."
    end

    def self.default_text(model, system_message)
      "Hello this is model #{model} with instruction #{system_message.to_s.inspect}! How can I assist you today?"
    end

    def self.tool_use_id
      "toolu_01A09q90qw90lq917835lq9"
    end

    def self.tool_arguments
      {:city=>"Austin", :state=>"TX", :country=>"US"}.to_json
    end

    # This response is a valid example response from the API.
    #
    # Stub this method to respond with something more specific if needed.
    def messages(**args)
      model = args.dig(:model) || "no model"
      system_message = args.dig(:system)
      tools = args.dig(:parameters, :tools)

      if proc = args.dig(:parameters, :stream)
        if tools
          # Streaming tool call response
          stream_tool_call(proc, model)
        else
          # Streaming text response
          proc.call({
            "id"=>"msg_01LtHY4sJVd7WBdPCsYb8kHQ",
            "type"=>"message",
            "role"=>"assistant",
            "delta"=>
              {"type"=>"text",
                "text"=> self.class.text || self.class.default_text(model, system_message)},
            "model"=>model,
            "stop_reason"=>"end_turn",
            "stop_sequence"=>nil,
            "usage"=>{"input_tokens"=>10, "output_tokens"=>19}
          })
        end
      else
        {
          "id"=>"msg_01LtHY4sJVd7WBdPCsYb8kHQ",
          "type"=>"message",
          "role"=>"assistant",
          "content"=>
            [{"type"=>"text",
              "text"=> self.class.text || self.class.default_text(model, system_message)}],
          "model"=> model,
          "stop_reason"=>"end_turn",
          "stop_sequence"=>nil,
          "usage"=>{"input_tokens"=>10, "output_tokens"=>19}
        }.dig("content", 0, "text")
      end
    end

    private

    def stream_tool_call(proc, model)
      function_name = self.class.function
      tool_id = self.class.tool_use_id
      tool_args = self.class.tool_arguments

      # Send content_block_start
      proc.call({
        "type" => "content_block_start",
        "index" => 0,
        "content_block" => {
          "type" => "tool_use",
          "id" => tool_id,
          "name" => function_name
        }
      })

      # Send input_json_delta events (split the JSON for realistic streaming)
      json_parts = [tool_args[0..tool_args.length/2], tool_args[tool_args.length/2+1..-1]]
      json_parts.each do |part|
        proc.call({
          "type" => "content_block_delta",
          "index" => 0,
          "delta" => {
            "type" => "input_json_delta",
            "partial_json" => part
          }
        })
      end

      # Send content_block_stop
      proc.call({
        "type" => "content_block_stop",
        "index" => 0
      })

      # Send message_start with usage
      proc.call({
        "type" => "message_start",
        "message" => {
          "usage" => {
            "input_tokens" => 10
          }
        }
      })

      # Send final usage
      proc.call({
        "type" => "message_delta",
        "usage" => {
          "output_tokens" => 25
        }
      })
    end
  end
end

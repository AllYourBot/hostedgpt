class TestClients::Anthropic
  def initialize(access_token:)
  end

  # This response is a valid example response from the API.
  #
  # Stub this method to respond with something more specific if needed.
  def messages(**args)
    {
      "id"=>"msg_01LtHY4sJVd7WBdPCsYb8kHQ",
      "type"=>"message",
      "role"=>"assistant",
      "content"=>
        [{"type"=>"text",
          "text"=>
          "Hello! It's nice to meet you. How can I assist you today?"}],
      "model"=>"claude-3-opus-20240229",
      "stop_reason"=>"end_turn",
      "stop_sequence"=>nil,
      "usage"=>{"input_tokens"=>10, "output_tokens"=>19}

    }.dig("content", 0, "text")
  end
end

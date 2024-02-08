class AiBackends::OpenAi
  attr :ai_model
  attr :client

  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClients::OpenAi class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      TestClients::OpenAi
    else
      OpenAI::Client
    end
  end

  def initialize(api_key)
    @client = self.class.client.new(access_token: api_key)
    @ai_model = "gpt-3.5-turbo"
  end

  # This method is used to get the next chat message from the AI backend.
  #
  # Messages should be an array of message hashes:
  #
  # messages = [
  #  { role: "user", content: "Hello" },
  #  # ...
  # ]
  def get_next_chat_message(existing_messages, &chunk_received_handler)
    response_handler = proc do |intermediate_response, bytesize|
      chunk = intermediate_response.dig("choices", 0, "delta", "content")
      print chunk if Rails.env.development?
      yield chunk if chunk
    rescue => e
      puts "Error in AiBackends::OpenAi response handler: #{e.message}"
      puts e.backtrace
    end

    response_handler = nil unless block_given?

    @client.chat(parameters: {
      model: ai_model,
      messages: existing_messages,
      temperature: 0.8,
      stream: response_handler,
      n: 1
    })
  end
end

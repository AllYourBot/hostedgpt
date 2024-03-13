class AIBackends::OpenAI
  attr :client

  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClients::OpenAI class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      TestClients::OpenAI
    else
      OpenAI::Client
    end
  end

  def initialize(user, assistant, conversation, message)
    raise OpenAI::ConfigurationError if user.openai_key.blank?
    @client = self.class.client.new(access_token: user.openai_key)
    @assistant = assistant
    @conversation = conversation
    @message = message
  end

  def get_next_chat_message(&chunk_received_handler)
    response_handler = proc do |intermediate_response, bytesize|
      chunk = intermediate_response.dig("choices", 0, "delta", "content")
      print chunk if Rails.env.development?
      yield chunk if chunk
    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue => e
      puts "\nError in AIBackends::OpenAI response handler: #{e.message}"
      puts e.backtrace
    end

    response_handler = nil unless block_given?

    response = @client.chat(parameters: {
      model: @assistant.model,
      messages: system_message + existing_messages,
      stream: response_handler,
      max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
    })

    if response.is_a?(Hash) && response.dig("choices")
      response.dig("choices", 0, "message", "content")
    else
      response
    end
  end

  private

  def system_message
    return [] if @assistant.instructions.blank?

    [{
      role: 'system',
      content: @assistant.instructions
    }]
  end

  def existing_messages
    @conversation.messages.ordered.where("created_at < ?", @message.created_at).collect do |message|
      if @assistant.images && message.documents.present?

        content = [{ type: "text", text: message.content_text }]
        content += message.documents.collect do |document|
          { type: "image_url", image_url: { url: document.file_data_url }}
        end

        {
          role: message.role,
          content: content
        }
      else
        {
          role: message.role,
          content: message.content_text
        }
      end
    end
  end
end

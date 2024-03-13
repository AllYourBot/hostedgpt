class AIBackends::Anthropic
  attr :client

  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClients::Anthropic class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      TestClients::Anthropic
    else
      Anthropic::Client
    end
  end

  def initialize(user, assistant, conversation, message)
    raise Anthropic::ConfigurationError if user.anthropic_key.blank?
    @client = self.class.client.new(access_token: user.anthropic_key)
    @assistant = assistant
    @conversation = conversation
    @message = message
  end

  def get_next_chat_message(&chunk_received_handler)
    response_handler = proc do |intermediate_response, bytesize|
      chunk = intermediate_response.dig("delta", "text")
      print chunk if Rails.env.development?
      yield chunk if chunk
    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue ::Faraday::UnauthorizedError => e
      raise Anthropic::ConfigurationError
    rescue => e
      puts "\nError in AIBackends::Anthropic response handler: #{e.message}"
      puts e.backtrace
    end

    response_handler = nil unless block_given?

    response = @client.messages(
      model: @assistant.model,
      system: @assistant.instructions,
      messages: existing_messages,
      parameters: {
        max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
        stream: response_handler,
      }
    )

    if response.is_a?(Hash) && response.dig("content")
      response.dig("content", 0, "text")
    else
      response
    end
  end

  private

  def existing_messages
    @conversation.messages.ordered.where("created_at < ?", @message.created_at).collect do |message|
      if @assistant.images && message.documents.present?

        content = [{ type: "text", text: message.content_text }]
        content += message.documents.collect do |document|
          { type: "image",
            source: {
              type: "base64",
              media_type: document.file.blob.content_type,
              data: document.file_base64,
            }
          }
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

class AIBackend::OpenAI < AIBackend
  include Tools

  IMAGE_MODEL = "gpt-image-1"
  SPEECH_MODEL = "tts-1"
  SPEECH_VOICE = "nova"

  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClient::OpenAI class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      ::TestClient::OpenAI
    else
      ::OpenAI::Client
    end
  end

  def self.test_execute(url, token, api_name)
    if Rails.env.test?
      client = ::TestClient::OpenAI.new(
        access_token: token,
        uri_base: url
      )
      response = client.send(:chat, ** {parameters: {model: api_name, messages: [{ role: "user", content: "Hello!" }]}})
    else
      Rails.logger.info "Connecting to OpenAI API server at #{url} with access token of length #{token.to_s.length}"
      client = ::OpenAI::Client.new(
        access_token: token,
        uri_base: url
      )

      Rails.logger.info "Testing using model #{api_name}"
      response = client.chat(parameters: {model: api_name, messages: [{ role: "user", content: "Hello!" }]})
    end

    response.dig("choices", 0, "message", "content")
  rescue ::Faraday::Error => e
    "Error: #{e.message}"
  end

  def self.generate_image(prompt:, user:)
    openai_service = canonical_service_for(user)

    if openai_service.nil? || openai_service.effective_token.blank?
      # Context-free on purpose: the toolbox that reaches this method knows the
      # current assistant and appends "to use image generation with ..." itself.
      raise "OpenAI API key not found. Image generation requires an OpenAI API key. Please configure your OpenAI API key in Settings > API Services"
    end

    response = client.new(access_token: openai_service.effective_token).images.generate(
      parameters: {
        prompt: prompt,
        model: IMAGE_MODEL,
        n: 1,
        size: "1024x1024",
        quality: "auto"
      }
    )

    b64_json = response.dig("data", 0, "b64_json") || response.dig(:data, 0, :b64_json)
    # The provider label is this implementation's own identity, stated as a
    # literal: subclasses inherit this method (Groq, OpenRouter), and self in
    # an inherited class method is the receiver, which would mislabel an
    # OpenAI-generated image with the vendor's name. A backend that ships
    # native image generation overrides this method and reports itself.
    { b64_json: b64_json, model: IMAGE_MODEL, provider: "OpenAI" }
  end

  def self.generate_speech(text:, user:)
    openai_service = canonical_service_for(user)
    raise AIBackend::ConfigurationError if openai_service.nil? || openai_service.effective_token.blank?

    client.new(access_token: openai_service.effective_token).audio.speech(
      parameters: {
        model: SPEECH_MODEL,
        input: text,
        voice: SPEECH_VOICE,
        response_format: "wav",
        speed: 1.0
      }
    )
  end

  # Scoped to the canonical OpenAI URL: Groq and OpenRouter services also
  # carry driver :openai, and their tokens are invalid at api.openai.com.
  def self.canonical_service_for(user)
    user.api_services.find_by(driver: :openai, url: APIService::URL_OPEN_AI)
  end
  private_class_method :canonical_service_for

  def self.key_error_message
    "(You need to enter a valid API key for OpenAI to use GPT. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find OpenAI Key instructions.)"
  end

  def self.billing_url
    "https://platform.openai.com/account/billing/overview"
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super(user, assistant, conversation, message)
    begin
      raise AIBackend::ConfigurationError if assistant.api_service.requires_token? && assistant.api_service.effective_token.blank?
      Rails.logger.info "Connecting to OpenAI API server at #{assistant.api_service.url} with access token of length #{assistant.api_service.effective_token.to_s.length}"
      @client = self.class.client.new(uri_base: assistant.api_service.url, access_token: assistant.api_service.effective_token, api_version: "")
    rescue ::Faraday::UnauthorizedError
      raise AIBackend::ConfigurationError
    end
  end

  private

  def client_method_name
    :chat
  end

  def set_client_config(config)
    super(config)

    @client_config = {
      parameters: {
        model: @assistant.language_model.api_name,
        messages: system_message(config[:instructions]) + config[:messages],
        stream: config[:streaming] && @response_handler || nil,
        max_completion_tokens: 2000, # we should really set this dynamically, based on the model, to the max
        stream_options: config[:streaming] && { include_usage: true } || nil,
        response_format: config[:json] ? { type: "json_object" } : { type: "text" },
        tools: @assistant.language_model.supports_tools? && Toolbox.tools || nil,
      }.compact.merge(config[:params] || {})
    }
  end

  def stream_handler(&chunk_handler)
    proc do |intermediate_response, bytesize|
      content_chunk = intermediate_response.dig("choices", 0, "delta", "content")
      tool_calls_chunk = intermediate_response.dig("choices", 0, "delta", "tool_calls")

      if (input_tokens, output_tokens = intermediate_response["usage"]&.values_at("prompt_tokens", "completion_tokens"))
        # https://platform.openai.com/docs/api-reference/chat/streaming
        @message.input_token_count = input_tokens
        @message.output_token_count = output_tokens
      end

      print content_chunk if Rails.env.development?
      if content_chunk
        @stream_response_text += content_chunk
        yield content_chunk
      end

      if tool_calls_chunk && tool_calls_chunk.is_a?(Array)
        tool_calls_chunk.each_with_index do |tool_call, i|
          @stream_response_tool_calls[i] ||= {}
          @stream_response_tool_calls[i] = deep_streaming_merge(@stream_response_tool_calls[i], tool_call)
        end
      end

    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue ::Faraday::UnauthorizedError => e
      raise AIBackend::ConfigurationError
    rescue => e
      Rails.logger.info "\nUnhandled error in AIBackend::OpenAI response handler: #{e.message}"
      Rails.logger.info e.backtrace.join("\n")
    end
  end

  def system_message(content)
    return [] if content.blank?

    [{
      role: "system",
      content:,
    }]
  end

  def preceding_conversation_messages
    history = conversation_history
    latest_user_message = latest_user_message(history)

    history.collect do |message|
      if message.user?
        user_message(message, with_time: message == latest_user_message)
      else
        begin
          parsed = JSON.parse(message.content_text)
          sanitized_content = if parsed.is_a?(Hash)
            parsed.except("message_to_user", "json_of_generated_image").to_json
          else
            message.content_text
          end
        rescue
          sanitized_content = message.content_text
        end

        {
          role: message.role,
          name: message.name_for_api,
          content: sanitized_content,
          tool_calls: message.assistant? ? message.content_tool_calls : nil, # only for some assistant messages
          tool_call_id: message.tool_call_id,     # only for tool messages
        }.compact.except( message.content_tool_calls.blank? && :tool_calls )
      end
    end
  end

  def user_message(message, with_time:)
    content = [{ type: "text", text: message.content_text || "" }]
    content += message.documents.filter_map { |document| document_part(document) }
    content << { type: "text", text: current_time_note } if with_time

    {
      role: message.role,
      name: message.name_for_api,
      content: text_only_as_string(content),
    }.compact
  end

  # Some OpenAI-compatible servers (Groq, local models) only accept string content for text-only models.
  def text_only_as_string(content)
    return content unless content.all? { |part| part[:type] == "text" }

    content.pluck(:text).join("\n\n")
  end

  def document_part(document)
    if document.has_image?
      { type: "image_url", image_url: { url: document.image_url(:large) }} if @assistant.supports_images?
    elsif document.has_document_pdf?
      return { type: "text", text: document.pdf_as_text } unless @assistant.supports_pdf?

      { type: "file", file: { filename: document.filename, file_data: "data:application/pdf;base64,#{document.file_base64}" }}
    end
  end

  def find_repeats_and_split(str)
    (1..str.length).each do |len|
      substring = str[0, len]
      repeated = substring * (str.length / len)
      return [substring] * (str.length / len) if repeated == str
    end
    [str]
  end
end

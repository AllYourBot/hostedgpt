class AIBackend::RubyLLM < AIBackend
  class ConfigurationError < StandardError; end
  class RateLimitError < StandardError; end

  CONFIGURATION_ERRORS = [
    ::RubyLLM::UnauthorizedError, ::RubyLLM::ConfigurationError,
    ::RubyLLM::BadRequestError, ::RubyLLM::ForbiddenError,
    ::RubyLLM::ContextLengthExceededError,
  ].freeze
  RATE_LIMIT_ERRORS = [
    ::RubyLLM::RateLimitError, ::RubyLLM::PaymentRequiredError,
    ::RubyLLM::OverloadedError, ::RubyLLM::ServiceUnavailableError,
  ].freeze

  def self.supports_driver?(driver)
    ["openai"].include?(driver)
  end

  def self.client
    Rails.env.test? ? ::TestClient::RubyLLM : ::RubyLLM
  end

  def self.gem_class
    Rails.env.test? ? ::TestClient::RubyLLM::Chat : ::RubyLLM::Chat
  end

  def self.test_execute(url, token, api_name)
    if Rails.env.test?
      chat = TestClient::RubyLLM::Chat.new(model: api_name, provider: :openai, assume_model_exists: true)
      chat.add_message({ role: "user", content: "Hello!" })
      chat.complete.content
    else
      Rails.logger.info "Connecting to OpenAI API server at #{url} with access token of length #{token.to_s.length}"
      Rails.logger.info "Testing using model #{api_name}"
      context = RubyLLM.context { |c| c.openai_api_key = token; c.openai_api_base = url if url != APIService::URL_OPEN_AI }
      chat = RubyLLM::Chat.new(model: api_name, provider: :openai, assume_model_exists: true, context: context)
      chat.add_message({ role: "user", content: "Hello!" })
      chat.complete.content
    end
  rescue ::Faraday::Error => e
    "Error: #{e.message}"
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super
    @api_service = assistant.api_service
    @token = @api_service.effective_token
    @api_name = assistant.language_model.api_name

    raise ConfigurationError if @api_service.requires_token? && @token.blank?
  end

  def get_oneoff_message(instructions, messages, params = {})
    chat = build_chat
    chat.with_instructions(instructions)
    preceding_messages(messages).each { |msg| chat.add_message(msg) }
    chat.with_params(**params) if params.present?
    chat.complete.content
  end

  def stream_next_conversation_message(&chunk_handler)
    @stream_response_text = ""

    chat = build_chat
    chat.with_instructions(full_instructions)
    preceding_conversation_messages.each { |msg| chat.add_message(msg) }
    chat.complete { |chunk| stream_handler.call(chunk, chunk_handler) }

    raise ::Faraday::ParsingError if @stream_response_text.blank?
    nil
  end

  private

  def build_chat
    self.class.gem_class.new(model: @api_name, provider: :openai, assume_model_exists: true, context: ruby_llm_context)
  end

  def ruby_llm_context
    self.class.client.context do |c|
      c.openai_api_key = @token
      c.openai_api_base = @api_service.url if @api_service.url != APIService::URL_OPEN_AI
    end
  end

  def stream_handler
    proc do |chunk, chunk_handler|
      input_tokens = chunk.respond_to?(:input_tokens) ? chunk.input_tokens : nil
      output_tokens = chunk.respond_to?(:output_tokens) ? chunk.output_tokens : nil

      if input_tokens && output_tokens
        @message.input_token_count = input_tokens
        @message.output_token_count = output_tokens
      end

      if chunk.respond_to?(:content) && chunk.content.present?
        @stream_response_text += chunk.content
        chunk_handler.call(chunk.content)
      end
    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue *CONFIGURATION_ERRORS => e
      raise ConfigurationError, e.message
    rescue *RATE_LIMIT_ERRORS => e
      raise RateLimitError, e.message
    rescue => e
      Rails.logger.info "\nUnhandled error in AIBackend::RubyLLM response handler: #{e.message}"
      Rails.logger.info e.backtrace.join("\n")
    end
  end

  def preceding_conversation_messages
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).collect do |message|
      next if message.tool?

      {
        role: message.role,
        content: message.content_text,
      }
    end.compact
  end

  def client_method_name
    raise NotImplementedError
  end

  def configuration_error
    raise NotImplementedError
  end

  def set_client_config(*)
    raise NotImplementedError
  end

  def format_parallel_tool_calls(*)
    raise NotImplementedError
  end
end

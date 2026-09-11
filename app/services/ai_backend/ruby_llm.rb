class AIBackend::RubyLLM < AIBackend
  # Inherits the base ConfigurationError so GetNextAIMessageJob's unified
  # `rescue AIBackend::ConfigurationError` catches bad-key failures and renders
  # key_error_message, instead of falling through to the generic 3x-retry path.
  class ConfigurationError < AIBackend::ConfigurationError; end
  class ToolCallIntercepted < StandardError; end

  IMAGE_MODEL = "gpt-image-1"

  CONFIGURATION_ERRORS = [
    ::RubyLLM::UnauthorizedError, ::RubyLLM::ConfigurationError,
    ::RubyLLM::BadRequestError, ::RubyLLM::ForbiddenError,
    ::RubyLLM::ContextLengthExceededError,
  ].freeze
  RATE_LIMIT_ERRORS = [
    ::RubyLLM::RateLimitError, ::RubyLLM::PaymentRequiredError,
    ::RubyLLM::OverloadedError, ::RubyLLM::ServiceUnavailableError,
  ].freeze

  # RubyLLM serves every chat provider identity: OpenAI, Anthropic, and Gemini
  # natively; Groq and OpenRouter over the openai-compatible path (the driver
  # is :openai with openai_api_base pointed at the service URL). Accepts
  # symbols or strings; callers pass both.
  def self.supports_identity?(identity)
    identity.present? && APIService.chat_provider_identities.include?(identity.to_sym)
  end

  def self.client
    Rails.env.test? ? ::TestClient::RubyLLM : ::RubyLLM
  end

  def self.gem_class
    Rails.env.test? ? ::TestClient::RubyLLM::Chat : ::AIBackend::RubyLLM::InterceptedChat
  end

  # One stanza per provider credential: the key plus, for openai-compatible
  # vendors (anything not the canonical OpenAI URL), the base URL override and
  # the traditional system role those servers expect.
  def self.configure_context(context, provider:, url:, token:)
    context.public_send("#{provider}_api_key=", token)
    if provider == :openai && url != APIService::URL_OPEN_AI
      context.openai_api_base = url
      context.openai_use_system_role = true
    end
  end

  def self.provider_for_url(url)
    if url&.include?("api.anthropic.com")
      :anthropic
    elsif url&.include?("generativelanguage.googleapis.com")
      :gemini
    else
      :openai
    end
  end

  def self.test_execute(url, token, api_name)
    provider = provider_for_url(url)
    if Rails.env.test?
      chat = TestClient::RubyLLM::Chat.new(model: api_name, provider: provider, assume_model_exists: true)
      chat.add_message({ role: "user", content: "Hello!" })
      chat.complete.content
    else
      Rails.logger.info "Connecting to AI API server at #{url} with access token of length #{token.to_s.length}"
      Rails.logger.info "Testing using model #{api_name} for provider #{provider}"
      context = RubyLLM.context { |c| configure_context(c, provider: provider, url: url, token: token) }
      chat = RubyLLM::Chat.new(model: api_name, provider: provider, assume_model_exists: true, context: context)
      chat.add_message({ role: "user", content: "Hello!" })
      chat.complete.content
    end
  rescue ::Faraday::Error => e
    "Error: #{e.message}"
  end

  # Image generation: the flag routes here via api_service.ai_backend instead
  # of the base AIBackend → AIBackend::OpenAI delegation. Image generation
  # always rides the user's OpenAI service (even when the chat backend is
  # Anthropic/Gemini) — same provider, different client. The flag-off path
  # keeps using AIBackend::OpenAI.generate_image until Phase 7.
  def self.generate_image(prompt:, user:)
    # Uses name "OpenAI" to avoid picking up Groq (also driver: :openai).
    openai_service = user.api_services.find_by(name: "OpenAI", driver: :openai)
    token = openai_service&.effective_token

    if openai_service.nil? || token.blank?
      current_backend = Current.message&.assistant&.language_model&.api_service&.name || "current AI backend"
      raise "OpenAI API key not found. Image generation requires an OpenAI API key. Please configure your OpenAI API key in Settings > API Services to use image generation with #{current_backend}."
    end

    context = client.context { |c| c.openai_api_key = token }
    image = context.paint(
      prompt,
      model: IMAGE_MODEL,
      provider: :openai,
      assume_model_exists: true,
      size: "1024x1024",
    )

    { b64_json: image.data, model: IMAGE_MODEL }
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super
    @api_service = assistant.api_service
    @token = @api_service.effective_token
    @api_name = assistant.language_model.api_name

    raise ConfigurationError if @api_service.requires_token? && @token.blank?
  end

  def get_oneoff_message(instructions, messages, params = {}, json: false)
    instructions = "#{instructions} Respond with ONLY valid JSON, no markdown or explanation." if json

    chat = build_chat
    chat.with_instructions(instructions)
    preceding_messages(messages).each { |msg| chat.add_message(msg) }
    chat.with_params(**params) if params.present?
    chat.complete.content
  rescue *CONFIGURATION_ERRORS => e
    raise ConfigurationError, e.message
  rescue *RATE_LIMIT_ERRORS => e
    raise ::Faraday::TooManyRequestsError, e.message
  end

  def stream_next_conversation_message(&chunk_handler)
    @stream_response_text = ""

    chat = build_chat
    instructions = full_instructions
    chat.with_instructions(conversation_instructions(instructions)) if instructions.present?
    preceding_conversation_messages.each { |msg| chat.add_message(msg) }
    chat.with_tools(*tool_instances) if tools_enabled?

    begin
      chat.complete { |chunk| stream_handler.call(chunk, chunk_handler) }
    rescue ToolCallIntercepted
      tool_calls = chat.messages.last&.tool_calls
      return format_tool_calls(tool_calls) if tool_calls.present?

      raise ::Faraday::ParsingError
    rescue *CONFIGURATION_ERRORS => e
      raise ConfigurationError, e.message
    rescue *RATE_LIMIT_ERRORS => e
      raise ::Faraday::TooManyRequestsError, e.message
    end

    raise ::Faraday::ParsingError if @stream_response_text.blank?
    nil
  end

  private

  def provider_slug
    @api_service.driver.to_sym
  end

  def build_chat
    chat = self.class.gem_class.new(model: @api_name, provider: provider_slug, assume_model_exists: true, context: ruby_llm_context)
    chat.with_headers(**AIBackend::OpenRouter.attribution_headers) if @api_service.provider_identity == :openrouter
    chat
  end

  # Anthropic caches only what it is told to, so mark the stable system prompt the way the SDK
  # backend does. OpenAI and Gemini cache a repeated prefix on their own.
  def conversation_instructions(instructions)
    return instructions unless provider_slug == :anthropic

    ::RubyLLM::Content::Raw.new([{ type: "text", text: instructions, cache_control: AIBackend::Anthropic::CACHE_CONTROL }])
  end

  def ruby_llm_context
    self.class.client.context { |c| self.class.configure_context(c, provider: provider_slug, url: @api_service.url, token: @token) }
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
      raise ::Faraday::TooManyRequestsError, e.message
    rescue => e
      Rails.logger.info "\nUnhandled error in AIBackend::RubyLLM response handler: #{e.message}"
      Rails.logger.info e.backtrace.join("\n")
    end
  end

  def preceding_conversation_messages
    history = conversation_history
    latest_user_message = latest_user_message(history)

    history.collect do |message|
      if message.tool?
        { role: :tool, content: message.content_text || "", tool_call_id: message.tool_call_id }
      elsif message.user?
        user_message(message, documents_for(message, history), with_time: message == latest_user_message)
      elsif message.assistant? && message.content_tool_calls.present?
        {
          role: :assistant,
          content: sanitize_content(message),
          tool_calls: tool_calls_hash(message),
        }
      else
        {
          role: message.role,
          content: sanitize_content(message),
        }
      end
    end.compact
  end

  # RubyLLM formats each attachment for the provider: a PDF becomes Anthropic's document block,
  # OpenAI's file part, or Gemini's inline data.
  def user_message(message, documents, with_time:)
    attachments = documents.select { |document| @assistant.natively_readable?(document) }.map { |document| ::RubyLLM::Attachment.new(document.file) }
    pdf_texts = documents.select { |document| document.has_document_pdf? && !@assistant.supports_pdf? }.map(&:pdf_as_text)
    text = [message.content_text, *pdf_texts, (current_time_note if with_time)].compact.join("\n\n")

    { role: message.role, content: attachments.any? ? ::RubyLLM::Content.new(text, attachments) : text }
  end

  # Reconstructs the stored OpenAI-shaped content_tool_calls (serialized via
  # JsonSerializer) into RubyLLM::ToolCall objects keyed by id — the shape
  # RubyLLM expects on a replayed assistant message. The thought signature
  # travels with the call because Gemini 3 rejects a functionCall replayed
  # without the signature it issued.
  def tool_calls_hash(message)
    message.content_tool_calls.each_with_object({}) do |tc, hash|
      id = tc[:id] || tc["id"]
      name = tc.dig(:function, :name) || tc.dig("function", "name")
      args = tc.dig(:function, :arguments) || tc.dig("function", "arguments") || "{}"
      args = JSON.parse(args) if args.is_a?(String)

      hash[id] = ::RubyLLM::ToolCall.new(
        id: id,
        name: name,
        arguments: args,
        thought_signature: tc[:thought_signature] || tc["thought_signature"],
      )
    end
  end

  def sanitize_content(message)
    return "" unless message.content_text.present?

    begin
      parsed = JSON.parse(message.content_text)
      if parsed.is_a?(Hash) && parsed.has_key?("json_of_generated_image")
        parsed.except("json_of_generated_image").to_json
      else
        message.content_text
      end
    rescue JSON::ParserError
      message.content_text
    end
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

  def tools_enabled?
    # The provider's tool policy is a provider fact, not a transport one:
    # LanguageModel#supports_tools? already consults the identity's backend,
    # so Groq's pinned denial holds no matter which transport serves the call.
    @assistant.language_model.supports_tools?
  end

  def tool_instances
    Toolbox.tools.map do |tool|
      AIBackend::RubyLLM::InterceptedTool.new(
        name: tool.dig(:function, :name),
        description: tool.dig(:function, :description),
        params_schema: tool.dig(:function, :parameters),
      )
    end
  end

  def format_tool_calls(tool_calls)
    tool_calls.values.map.with_index do |tc, i|
      { index: i, type: "function", id: tc.id,
        thought_signature: tc.thought_signature,
        function: { name: tc.name, arguments: tc.arguments.to_json } }.compact
    end
  end

  # RubyLLM returns tool calls already separated, so these defensive identities
  # satisfy the AIBackend::Tools contract even though the overridden
  # stream_next_conversation_message never calls them.
  def format_parallel_tool_calls(content_tool_calls)
    content_tool_calls
  end

  def parallel_tool_calls(content_tool_calls)
    content_tool_calls
  end
end

class AIBackend::RubyLLM < AIBackend
  # Inherits the base ConfigurationError so GetNextAIMessageJob's unified
  # `rescue AIBackend::ConfigurationError` catches bad-key failures and renders
  # key_error_message, instead of falling through to the generic 3x-retry path.
  class ConfigurationError < AIBackend::ConfigurationError; end

  IMAGE_MODEL = "gpt-image-2.5-flare"
  SPEECH_MODEL = "tts-1"
  SPEECH_VOICE = "nova"
  GEMINI_SPEECH_MODEL = "gemini-3.1-flash-tts-preview"
  GEMINI_SPEECH_VOICE = "Kore"

  # "high" is the API's own default effort. Thinking counts toward max_tokens, so
  # the 4096 RubyLLM falls back to for an assumed model can be spent before the
  # answer starts.
  THINKING_EFFORT = "high"
  THINKING_BUDGET = 16_000
  THINKING_MAX_TOKENS = 16_000

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

  # Error-detail parity with the SDK transports, whose failures name the model.
  ERROR_BODY_EXCERPT_LENGTH = 200
  API_KEY_LIKE = /(sk-|gsk_|gsk-|AIza)[\w\-]+/.freeze

  def self.error_detail(error, model:)
    detail = +"model: #{model}"
    if (response = error.try(:response)) && response.respond_to?(:status)
      body = response.body.to_s.gsub(API_KEY_LIKE, '\1' + "*" * 40).slice(0, ERROR_BODY_EXCERPT_LENGTH)
      detail << ", status: #{response.status}, body: #{body}"
    end
    detail
  end

  def self.mapped_error(error, model:, as:)
    as.new("#{error.message} (#{error_detail(error, model: model)})")
  end

  def self.gem_class
    Rails.env.test? ? ::TestClient::RubyLLM::Chat : ::RubyLLM::Chat
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

  # The canonical-URL token, not the driver alone: Groq and OpenRouter also
  # ride driver :openai, and their tokens are invalid at api.openai.com.
  def self.canonical_openai_token(user)
    service = user.api_services.find_by(driver: :openai, url: APIService::URL_OPEN_AI)
    service&.effective_token
  end

  def self.canonical_gemini_token(user)
    user.api_services.find_by(driver: :gemini, url: APIService::URL_GEMINI)&.effective_token
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
    Rails.logger.info "Connecting to AI API server at #{url} with access token of length #{token.to_s.length}"
    Rails.logger.info "Testing using model #{api_name} for provider #{provider}"
    context = client.context { |c| configure_context(c, provider: provider, url: url, token: token) }
    chat = gem_class.new(model: api_name, provider: provider, assume_model_exists: true, context: context)
    chat.add_message({ role: "user", content: "Hello!" })
    chat.complete.content
  rescue ::RubyLLM::Error, ::Faraday::Error => e
    "Error: #{e.message}"
  end

  # Always paints through the user's OpenAI service, even for an Anthropic or Gemini assistant.
  def self.generate_image(prompt:, user:)
    token = canonical_openai_token(user)

    # Context-free on purpose: Toolbox::Image#generate_with_error_context appends which assistant asked.
    raise "OpenAI API key not found. Image generation requires an OpenAI API key. Please configure your OpenAI API key in Settings > API Services" if token.blank?

    context = client.context { |c| c.openai_api_key = token }
    image = begin
      context.paint(
        prompt,
        model: IMAGE_MODEL,
        provider: :openai,
        assume_model_exists: true,
        size: "1024x1024",
      )
    rescue *CONFIGURATION_ERRORS => e
      raise mapped_error(e, model: IMAGE_MODEL, as: ConfigurationError)
    rescue *RATE_LIMIT_ERRORS => e
      raise mapped_error(e, model: IMAGE_MODEL, as: ::Faraday::TooManyRequestsError)
    end

    { b64_json: image.data, model: IMAGE_MODEL, provider: "OpenAI" }
  end

  def self.generate_speech(text:, user:)
    if (token = canonical_openai_token(user)).present?
      speak(text, provider: :openai, token:, model: SPEECH_MODEL, voice: SPEECH_VOICE,
        format: "wav", provider_options: { speed: 1.0 })
    elsif (token = canonical_gemini_token(user)).present?
      WavAudio.from_pcm(speak(text, provider: :gemini, token:, model: GEMINI_SPEECH_MODEL, voice: GEMINI_SPEECH_VOICE))
    else
      raise ConfigurationError # message-free: the controller renders the key message
    end
  end

  def self.speak(text, provider:, token:, model:, **options)
    context = client.context { |c| c.public_send("#{provider}_api_key=", token) }
    context.speak(text, model:, provider:, assume_model_exists: true, **options).to_blob
  rescue ::RubyLLM::BadRequestError => e # ahead of CONFIGURATION_ERRORS, which also holds it
    gemini_rejected_key = e.message.match?(/api key/i)
    raise mapped_error(e, model:, as: gemini_rejected_key ? ConfigurationError : ::Faraday::BadRequestError)
  rescue *CONFIGURATION_ERRORS => e
    raise mapped_error(e, model:, as: ConfigurationError)
  rescue *RATE_LIMIT_ERRORS => e
    raise mapped_error(e, model:, as: ::Faraday::TooManyRequestsError)
  rescue ::RubyLLM::Error => e
    raise mapped_error(e, model:, as: ::Faraday::ServerError)
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
    chat.with_provider_options(**params) if params.present?
    chat.complete.content
  rescue *CONFIGURATION_ERRORS => e
    raise self.class.mapped_error(e, model: @api_name, as: ConfigurationError)
  rescue *RATE_LIMIT_ERRORS => e
    raise self.class.mapped_error(e, model: @api_name, as: ::Faraday::TooManyRequestsError)
  end

  def stream_next_conversation_message(&chunk_handler)
    @stream_response_text = ""

    chat = build_chat
    instructions = full_instructions
    # Anthropic caches only what it is told to, so mark the stable system
    # prompt as the cache boundary. OpenAI and Gemini cache a repeated prefix
    # on their own.
    chat.with_instructions(instructions, cache_until_here: provider_slug == :anthropic) if instructions.present?
    preceding_conversation_messages.each { |msg| chat.add_message(msg) }
    chat.with_tools(*tool_instances) if tools_enabled?
    if thinking_enabled?
      chat.with_thinking(**thinking_options)
      chat.with_provider_options(max_tokens: THINKING_MAX_TOKENS) if provider_slug == :anthropic
    end

    begin
      # `generate` streams chunks and never executes tools — the tool calls come
      # back on the returned message for the job to run through Toolbox.call.
      response = chat.generate { |chunk| stream_handler.call(chunk, chunk_handler) }
    rescue *CONFIGURATION_ERRORS => e
      raise self.class.mapped_error(e, model: @api_name, as: ConfigurationError)
    rescue *RATE_LIMIT_ERRORS => e
      raise self.class.mapped_error(e, model: @api_name, as: ::Faraday::TooManyRequestsError)
    end

    # Tool calls win over the blank-response check: the job's `not_finished?`
    # gate depends on the call array arriving even without streamed text.
    tool_calls = response.tool_calls
    return format_tool_calls(tool_calls) if tool_calls.present?

    raise ::Faraday::ParsingError if @stream_response_text.blank?
    nil
  end

  private

  def provider_slug
    @api_service.driver.to_sym
  end

  def build_chat
    chat = self.class.gem_class.new(model: @api_name, provider: provider_slug, assume_model_exists: true, context: ruby_llm_context)
    chat.with_headers(**AIBackend::Policy::OpenRouter.attribution_headers) if @api_service.provider_identity == :openrouter
    chat
  end

  def ruby_llm_context
    self.class.client.context { |c| self.class.configure_context(c, provider: provider_slug, url: @api_service.url, token: @token) }
  end

  def stream_handler
    proc do |chunk, chunk_handler|
      tokens = chunk.respond_to?(:tokens) ? chunk.tokens : nil
      input_tokens = tokens&.input
      output_tokens = tokens&.output

      if input_tokens && output_tokens
        @message.input_token_count = input_tokens
        @message.output_token_count = output_tokens
      end

      thinking = chunk.respond_to?(:thinking) ? chunk.thinking : nil
      if thinking
        @message.thinking_text = "#{@message.thinking_text}#{thinking.text}" if thinking.text.present?
        @message.thinking_signature ||= thinking.signature.presence
        chunk_handler.call("") # lets the job broadcast the thinking so far and check for a cancel
      end

      if chunk.respond_to?(:content) && chunk.content.present?
        @stream_response_text += chunk.content
        chunk_handler.call(chunk.content)
      end
    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue *CONFIGURATION_ERRORS => e
      raise self.class.mapped_error(e, model: @api_name, as: ConfigurationError)
    rescue *RATE_LIMIT_ERRORS => e
      raise self.class.mapped_error(e, model: @api_name, as: ::Faraday::TooManyRequestsError)
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
          thinking: thinking_for(message),
        }.compact
      else
        {
          role: message.role,
          content: sanitize_content(message),
          thinking: (thinking_for(message) if message.assistant?),
        }.compact
      end
    end.compact
  end

  # Anthropic verifies replayed thinking by its signature, so thinking without one
  # (a cancelled response) is left out.
  def thinking_for(message)
    return if message.thinking_signature.blank?

    ::RubyLLM::Thinking.build(text: message.thinking_text, signature: message.thinking_signature)
  end

  # RubyLLM formats each attachment for the provider: a PDF becomes Anthropic's document block,
  # OpenAI's file part, or Gemini's inline data.
  def user_message(message, documents, with_time:)
    attachments = documents.select { |document| @assistant.natively_readable?(document) }.map { |document| attachment_for(document) }
    pdf_texts = documents.select { |document| document.has_document_pdf? && !@assistant.supports_pdf? }.map(&:pdf_as_text)
    text = [message.content_text, *pdf_texts, (current_time_note if with_time)].compact.join("\n\n")

    msg = { role: message.role, content: text }
    msg[:attachments] = attachments if attachments.any?
    msg
  end

  # Images go as the :large variant, as the SDK backends send them: an original photo can
  # exceed a provider's limit (5 MB for Anthropic), and the history resends it every turn.
  def attachment_for(document)
    file = document.has_image? ? document.image_variant(:large).processed.image : document.file
    ::RubyLLM::Attachment.new(file)
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
    # LanguageModel#supports_tools? already consults the identity's policy,
    # so Groq's pinned denial holds no matter which transport serves the call.
    @assistant.language_model.supports_tools?
  end

  def thinking_enabled?
    @assistant.language_model.supports_thinking?
  end

  def thinking_options
    return { budget: THINKING_BUDGET, display: "summarized" } if provider_slug == :gemini && @api_name.start_with?("gemini-2.5")

    { effort: THINKING_EFFORT, display: "summarized" }
  end

  def tool_instances
    Toolbox.tools.map do |tool|
      AIBackend::RubyLLM::ToolSchema.new(
        name: tool.dig(:function, :name),
        description: tool.dig(:function, :description),
        parameters_schema: tool.dig(:function, :parameters),
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
  # satisfy the AIBackend::Tools contract even though
  # stream_next_conversation_message never calls them.
  def format_parallel_tool_calls(content_tool_calls)
    content_tool_calls
  end

  def parallel_tool_calls(content_tool_calls)
    content_tool_calls
  end
end

class AIBackend
  include Tools

  class ToolCallIntercepted < StandardError; end
  class BlankResponseError < StandardError; end

  class_attribute :chat_factory, default: ->(context, api_name, provider, assistant = nil) {
    context.chat(model: api_name, provider: provider, assume_model_exists: true)
  }

  attr_reader :chat

  def initialize(user, assistant, conversation = nil, message = nil)
    @user = user
    @assistant = assistant
    @conversation = conversation
    @message = message
  end

  def get_oneoff_message(instructions, messages, params = {})
    chat = build_chat
    chat.with_instructions(instructions)

    messages.each_with_index do |msg, i|
      role = (i % 2).even? ? :user : :assistant
      chat.add_message(role: role, content: msg)
    end

    chat.with_params(**params) if params.present?

    response = chat.complete
    response.respond_to?(:content) ? response.content : response.to_s
  rescue RubyLLM::UnauthorizedError
    raise RubyLLM::ConfigurationError
  end

  def stream_next_conversation_message(&chunk_handler)
    stream_response_text = +""

    chat = build_chat
    @chat = chat
    chat.with_instructions(full_instructions)

    preceding_conversation_messages.each do |msg|
      chat.add_message(msg)
    end

    if @assistant.language_model.supports_tools?
      register_tools(chat)
    end

    begin
      chat.complete do |chunk|
        handle_stream_chunk(chunk, stream_response_text, &chunk_handler)
      end
    rescue ToolCallIntercepted
      return format_tool_calls_if_present(chat)
    rescue RubyLLM::UnauthorizedError
      raise RubyLLM::ConfigurationError
    end

    return format_tool_calls_if_present(chat) if chat.messages.last&.tool_calls.present?

    if stream_response_text.blank?
      raise BlankResponseError, "No content was streamed"
    end

    nil
  end

  def self.test_language_model(language_model, api_name = nil)
    api_name ||= language_model.api_name
    url = language_model.api_service.url
    token = language_model.api_service.effective_token
    return "Error: API key (token) is blank" if language_model.api_service.requires_token? && token.blank?

    test_execute(url, token, api_name, language_model.api_service.driver)
  end

  def self.test_api_service(api_service, url = nil, token = nil)
    url ||= api_service.url
    token ||= api_service.effective_token
    language_model = api_service.language_models.first
    api_name = language_model&.api_name

    return "Error: API key (token) is blank" if api_service.requires_token? && token.blank?
    return "Error: API name is blank. Define a Language Model for this API service." if api_name.blank?

    test_execute(url, token, api_name, api_service.driver)
  end

  private

  def handle_stream_chunk(chunk, stream_response_text)
    if chunk.respond_to?(:content) && chunk.content
      stream_response_text << chunk.content
      yield chunk.content
    end

    if chunk.respond_to?(:tokens) && chunk.tokens
      @message.input_token_count = chunk.tokens.input if chunk.tokens.input
      @message.output_token_count = chunk.tokens.output if chunk.tokens.output
    end
  end

  def build_chat
    api_service = @assistant.api_service
    token = api_service.effective_token

    if api_service.requires_token? && token.blank?
      raise RubyLLM::ConfigurationError
    end

    provider = self.class.ruby_llm_provider(api_service.driver)
    api_name = @assistant.language_model.api_name

    ctx = RubyLLM.context do |config|
      self.class.set_provider_key(config, api_service.driver, token)
      self.class.set_provider_base(config, api_service.driver, api_service.url)
    end

    AIBackend.chat_factory.call(ctx, api_name, provider, @assistant)
  end

  def register_tools(chat)
    tools = Toolbox.tools
    return if tools.blank?

    intercepted = tools.map { |tool_def| InterceptedTool.new(tool_def) }
    chat.with_tools(*intercepted)
  end

  def format_tool_calls_if_present(chat)
    tool_calls = chat.messages.last&.tool_calls
    format_tool_calls(tool_calls) if tool_calls.present?
  end

  def format_tool_calls(ruby_llm_tool_calls)
    ruby_llm_tool_calls.values.map.with_index do |tc, i|
      {
        index: i,
        type: "function",
        id: tc.id,
        function: {
          name: tc.name,
          arguments: tc.arguments.to_json
        }
      }
    end
  end

  def preceding_conversation_messages
    @conversation.messages.for_conversation_version(@message.version)
      .where("messages.index < ?", @message.index)
      .includes(documents: {file_attachment: :blob})
      .collect do |message|
        build_message_for_chat(message)
      end
  end

  def build_message_for_chat(message)
    if message.tool?
      {role: :tool, content: message.content_text || "", tool_call_id: message.tool_call_id}
    elsif @assistant.supports_images? && message.documents.present? && message.role == "user"
      build_multimodal_message(message)
    elsif message.assistant? && message.content_tool_calls.present?
      build_assistant_with_tool_calls_message(message)
    else
      {role: message.role.to_sym, content: sanitize_content(message.content_text)}
    end
  end

  def build_multimodal_message(message)
    text_parts = [message.content_text]
    attachments = []

    message.documents.each do |document|
      if document.has_image? || document.has_document_pdf?
        attachments << document.file
      end

      if document.has_document_pdf?
        pdf_text = document.extract_pdf_text
        text_parts << if pdf_text.present?
          "\n\n[PDF Document: #{document.filename}]\n#{pdf_text}"
        else
          "\n\n[PDF Document: #{document.filename} - Unable to extract text from this PDF]"
        end
      end
    end

    text = text_parts.compact_blank.join("\n\n")
    {role: message.role.to_sym, content: RubyLLM::Content.new(text, attachments)}
  end

  def build_assistant_with_tool_calls_message(message)
    tool_calls_hash = {}
    message.content_tool_calls.each do |tc|
      id = tc["id"] || tc[:id]
      name = tc.dig("function", "name") || tc.dig(:function, :name)
      args = tc.dig("function", "arguments") || tc.dig(:function, :arguments) || "{}"
      args_hash = if args.is_a?(String)
        begin
          JSON.parse(args)
        rescue
          {}
        end
      else
        args
      end

      tool_calls_hash[id] = RubyLLM::ToolCall.new(id: id, name: name, arguments: args_hash)
    end

    {role: :assistant, content: message.content_text || "", tool_calls: tool_calls_hash}
  end

  EXTRACTED_TOOL_PAYLOAD_KEYS = %w[message_to_user json_of_generated_image].freeze

  def sanitize_content(content_text)
    return content_text if content_text.nil? || !content_text.is_a?(String)
    return content_text unless content_text.start_with?("{", "[")

    begin
      parsed = JSON.parse(content_text)
      parsed.is_a?(Hash) ? parsed.except(*EXTRACTED_TOOL_PAYLOAD_KEYS).to_json : content_text
    rescue
      content_text
    end
  end

  def full_instructions
    s = @assistant.instructions.to_s

    if @user.memories.present?
      s += "\n\nNote these additional items that you've been told and remembered:\n\n"
      s += @user.memories.pluck(:detail).join("\n")
    end

    now = DateTime.current
    s += "\n\nFor the user, the current time is #{now.strftime("%-l:%M%P")}; the current date is #{now.strftime("%A, %B %-d, %Y")}"
    s.strip
  end

  class InterceptedTool < RubyLLM::Tool
    def initialize(tool_def)
      @tool_name = tool_def.dig(:function, :name) || tool_def.dig("function", "name")
      @tool_description = tool_def.dig(:function, :description) || tool_def.dig("function", "description")
      @tool_schema = tool_def.dig(:function, :parameters) || tool_def.dig("function", "parameters") || {"type" => "object", "properties" => {}, "required" => []}
    end

    def name
      @tool_name
    end

    def description
      @tool_description
    end

    def params_schema
      @tool_schema
    end

    def execute(**)
      raise AIBackend::ToolCallIntercepted
    end
  end

  class << self
    def ruby_llm_provider(driver)
      case driver
      when "openai" then :openai
      when "anthropic" then :anthropic
      when "gemini" then :gemini
      else
        raise ArgumentError, "Unknown driver: #{driver.inspect}"
      end
    end

    def set_provider_key(config, driver, token)
      case driver
      when "openai" then config.openai_api_key = token
      when "anthropic" then config.anthropic_api_key = token
      when "gemini" then config.gemini_api_key = token
      end
    end

    def set_provider_base(config, driver, url)
      case driver
      when "openai"
        config.openai_api_base = url unless url == APIService::URL_OPEN_AI
      when "anthropic"
        config.anthropic_api_base = url unless url == APIService::URL_ANTHROPIC
      when "gemini"
        config.gemini_api_base = url unless url == APIService::URL_GEMINI
      end
    end

    def test_execute(url, token, api_name, driver)
      provider = ruby_llm_provider(driver)

      ctx = RubyLLM.context do |config|
        set_provider_key(config, driver, token)
        set_provider_base(config, driver, url)
      end

      chat = AIBackend.chat_factory.call(ctx, api_name, provider, nil)
      response = chat.ask("Hello!")
      response.content
    rescue RubyLLM::ConfigurationError => e
      raise e
    rescue => e
      "Error: #{e.message}"
    end
  end
end

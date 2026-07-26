# frozen_string_literal: true

class AIBackend::RubyLLM < AIBackend
  class ConfigurationError < StandardError; end
  class RateLimitError < StandardError; end

  CONFIGURATION_ERRORS = [
    ::RubyLLM::UnauthorizedError,
    ::RubyLLM::BadRequestError,
    ::RubyLLM::ConfigurationError,
    ::RubyLLM::ForbiddenError,
    ::RubyLLM::ContextLengthExceededError,
  ].freeze

  RATE_LIMIT_ERRORS = [
    ::RubyLLM::RateLimitError,
    ::RubyLLM::OverloadedError,
    ::RubyLLM::ServiceUnavailableError,
    ::RubyLLM::PaymentRequiredError,
  ].freeze

  def self.client
    ::RubyLLM
  end

  def self.chat_class
    ::AIBackend::RubyLLM::InterceptedChat
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super
    raise AIBackend::RubyLLM::ConfigurationError if assistant.api_service.requires_token? && assistant.api_service.effective_token.blank?
    @client = self.class.client
  end

  def get_oneoff_message(instructions, messages, params = {})
    chat = build_chat(params: params)
    chat.with_instructions(instructions)
    preceding_messages(messages).each { |msg| chat.add_message(msg) }

    response = chat.complete
    response.content
  rescue *CONFIGURATION_ERRORS => e
    raise AIBackend::RubyLLM::ConfigurationError, e.message
  rescue *RATE_LIMIT_ERRORS => e
    raise AIBackend::RubyLLM::RateLimitError, e.message
  end

  def stream_next_conversation_message(&chunk_handler)
    raise "No chunk handler given" unless block_given?

    @stream_response_text = ""

    chat = build_chat
    chat.with_instructions(full_instructions)
    preceding_conversation_messages.each { |msg| chat.add_message(msg) }

    response = chat.complete(&stream_handler(&chunk_handler))

    if response.respond_to?(:tool_calls) && response.tool_calls.present?
      return format_tool_calls_from_response(response.tool_calls)
    elsif @stream_response_text.blank?
      raise ::Faraday::ParsingError
    end
  rescue *CONFIGURATION_ERRORS => e
    raise AIBackend::RubyLLM::ConfigurationError, e.message
  rescue *RATE_LIMIT_ERRORS => e
    raise AIBackend::RubyLLM::RateLimitError, e.message
  end

  def self.test_execute(url, token, api_name)
    provider = provider_for_url(url)

    context = client.context do |config|
      config.public_send("#{provider}_api_key=", token)
      config.public_send("#{provider}_api_base=", url)
    end

    chat = chat_class.new(
      model: api_name,
      provider: provider,
      assume_model_exists: true,
      context: context,
    )
    chat.with_instructions("You are a helpful assistant.")
    chat.add_message(role: :user, content: "Hello!")
    response = chat.complete
    response.content
  rescue ::RubyLLM::Error, ::RubyLLM::ConfigurationError => e
    "Error: #{e.message}"
  rescue => e
    "Error: #{e.message}"
  end

  def self.provider_for_url(url)
    case url.to_s
    when /anthropic/i
      :anthropic
    when /google|gemini|generativelanguage/i
      :gemini
    else
      :openai
    end
  end
  private_class_method :provider_for_url

  private

  def build_chat(params: {})
    context = ruby_llm_context
    chat = self.class.chat_class.new(
      model: @assistant.language_model.api_name,
      provider: provider_slug,
      assume_model_exists: true,
      context: context,
    )
    chat.with_params(**(params || {}))
    chat.with_tools(*tool_instances) if @assistant.language_model.supports_tools?
    chat
  end

  def ruby_llm_context
    @client.context do |config|
      config.public_send("#{provider_slug}_api_key=", @assistant.api_service.effective_token)
      config.public_send("#{provider_slug}_api_base=", api_base_url)
    end
  end

  def provider_slug
    @assistant.language_model.api_service.driver.to_sym
  end

  def api_base_url
    @assistant.language_model.api_service.url
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

  def stream_handler(&chunk_handler)
    proc do |chunk|
      if (input_tokens = chunk.input_tokens)
        @message.input_token_count = input_tokens
      end
      if (output_tokens = chunk.output_tokens)
        @message.output_token_count = output_tokens
      end

      content = chunk.content
      if content.present?
        @stream_response_text += content
        chunk_handler.call(content)
      end
    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue *CONFIGURATION_ERRORS => e
      raise AIBackend::RubyLLM::ConfigurationError, e.message
    rescue *RATE_LIMIT_ERRORS => e
      raise AIBackend::RubyLLM::RateLimitError, e.message
    rescue NoMethodError, TypeError => e
      raise e
    rescue => e
      Rails.logger.info "\nUnhandled error in AIBackend::RubyLLM response handler: #{e.message}"
      Rails.logger.info e.backtrace.join("\n")
    end
  end

  def format_tool_calls_from_response(tool_calls)
    tool_calls.values.map do |tc|
      arguments = tc.arguments
      arguments = arguments.to_json unless arguments.is_a?(String)

      {
        "id" => tc.id,
        "type" => "function",
        "function" => {
          "name" => tc.name,
          "arguments" => arguments
        }
      }
    end
  end

  def preceding_conversation_messages
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).collect do |message|
      if @assistant.supports_images? && message.documents.present? && message.role == "user"
        content_with_media = build_multimodal_content(message)

        {
          role: message.role.to_sym,
          content: ::RubyLLM::Content::Raw.new(content_with_media)
        }
      else
        formatted = {
          role: message.role.to_sym,
          content: sanitized_tool_content(message)
        }
        formatted[:tool_call_id] = message.tool_call_id if message.tool_call_id.present?
        if message.assistant? && message.content_tool_calls.present?
          formatted[:tool_calls] = message.content_tool_calls.each_with_object({}) do |tc, hash|
            args = tc.dig("function", "arguments") || tc.dig(:function, :arguments) || "{}"
            args = begin
              JSON.parse(args)
            rescue JSON::ParserError
              {}
            end if args.is_a?(String)
            id = tc["id"] || tc[:id]
            hash[id] = ::RubyLLM::ToolCall.new(
              id: id,
              name: tc.dig("function", "name") || tc.dig(:function, :name),
              arguments: args,
            )
          end
        end
        formatted
      end
    end
  end

  def build_multimodal_content(message)
    content_with_media = if provider_slug == :gemini
      [{ text: message.content_text }]
    else
      [{ type: "text", text: message.content_text }]
    end

    message.documents.each do |document|
      if document.has_image?
        content_with_media << build_image_content(document)
      elsif document.has_document_pdf?
        pdf_text = document.extract_pdf_text
        if pdf_text.present?
          if provider_slug == :gemini
            content_with_media << { text: "\n\n[PDF Document: #{document.filename}]\n#{pdf_text}" }
          else
            content_with_media << { type: "text", text: "\n\n[PDF Document: #{document.filename}]\n#{pdf_text}" }
          end
        else
          if provider_slug == :gemini
            content_with_media << { text: "\n[PDF Document: #{document.filename} - Unable to extract text from this PDF]" }
          else
            content_with_media << { type: "text", text: "\n[PDF Document: #{document.filename} - Unable to extract text from this PDF]" }
          end
        end
      end
    end

    content_with_media
  end

  def build_image_content(document)
    case provider_slug
    when :anthropic
      {
        type: "image",
        source: {
          type: "base64",
          media_type: document.file.blob.content_type,
          data: document.file_base64(:large),
        }
      }
    when :gemini
      {
        inline_data: {
          mime_type: document.file.blob.content_type,
          data: document.file_base64(:large),
        }
      }
    else
      { type: "image_url", image_url: { url: document.image_url(:large) } }
    end
  end

  def sanitized_tool_content(message)
    return message.content_text || "" unless message.tool?

    content_text = message.content_text || ""
    begin
      parsed = JSON.parse(content_text)
      if parsed.is_a?(Hash)
        parsed.except("message_to_user", "json_of_generated_image").to_json
      else
        content_text
      end
    rescue JSON::ParserError
      content_text
    end
  end

  def configuration_error
    AIBackend::RubyLLM::ConfigurationError
  end
end

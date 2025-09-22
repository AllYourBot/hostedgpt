include ActionView::RecordIdentifier
require "nokogiri/xml/node"

class ::Gemini::Errors::ConfigurationError < ::Gemini::Errors::GeminiError; end

class GetNextAIMessageJob < ApplicationJob
  include ActionView::Helpers::RenderingHelper
  class ResponseCancelled < StandardError; end
  class WaitForPrevious < StandardError; end

  retry_on WaitForPrevious, wait: ->(run) { (2**run - 1).seconds }, attempts: 3

  def ai_backend
    @assistant.language_model.ai_backend
  end

  def perform(user_id, message_id, assistant_id, attempt = 1)
    Rails.logger.info "### GetNextAIMessageJob.perform(#{user_id}, #{message_id}, #{assistant_id}, #{attempt})" unless Rails.env.test?

    @user         = User.find(user_id)
    @message      = Message.find(message_id)
    @conversation = @message.conversation
    @assistant    = Assistant.find(assistant_id)
    @prev_message = @conversation.messages.assistant.for_conversation_version(@message.version).find_by(index: @message.index-1)
    @attempt      = attempt

    return false          if generation_was_cancelled? || message_is_populated?
    raise WaitForPrevious if @prev_message&.not_finished?

    last_sent_at = Time.current
    @message.update!(processed_at: Time.current, content_text: "")
    GetNextAIMessageJob.broadcast_updated_message(@message, thinking: true) # thinking shows dot, signaling to user that we're waiting now on ai_backend

    Rails.logger.info "\n### Wait for reply" unless Rails.env.test?

    response = Current.set(user: @user, message: @message) do
      ai_backend.new(@conversation.user, @assistant, @conversation, @message)
      .stream_next_conversation_message do |content_chunk|
        @message.content_text += content_chunk

        if Time.current.to_f - last_sent_at.to_f >= 0.1
          GetNextAIMessageJob.broadcast_updated_message(@message, thinking: true)
          last_sent_at = Time.current
        end

        if generation_was_cancelled?
          @message.cancelled_at = Time.current
          raise ResponseCancelled
        end
      end
    end
    @message.content_tool_calls = response # Typically, stream_next_conversation_message will simply return nil because it executes
                                           # the content_chunk block to return it's response incrementally. However, tool_call
                                           # responses don't make sense to stream because they can't be executed incrementally
                                           # so we just return the full tool response message at once. The only time we return
                                           # like this is for tool_calls so we know we can simply assign it here.

    raise Faraday::ParsingError if @message.not_finished?

    wrap_up_the_message
    return true

  rescue ResponseCancelled => e
    Rails.logger.info "\n### Response cancelled in GetNextAIMessageJob(#{message_id})" unless Rails.env.test?
    wrap_up_the_message
    return true
  rescue OpenAI::ConfigurationError => e
    name = @assistant.language_model.api_service.name
    if name == "OpenAI"
      set_openai_error
    elsif name == "Groq"
      set_groq_error
    else
      set_generic_error(name)
    end
    wrap_up_the_message
    return true
  rescue Anthropic::ConfigurationError => e
    set_anthropic_error
    wrap_up_the_message
    return true
  rescue Gemini::Errors::ConfigurationError => e
    set_generic_error("Gemini")
    wrap_up_the_message
    return true
  rescue Faraday::ParsingError => e
    set_response_error
    wrap_up_the_message
    return true
  rescue Faraday::ConnectionFailed => e
    @message.content_text = "I experienced a connection error. #{e.message}"
    wrap_up_the_message
    return true
  rescue Faraday::TooManyRequestsError => e
    set_billing_error
    wrap_up_the_message
    return true
  rescue WaitForPrevious
    Rails.logger.info "\n### WaitForPrevious in GetNextAIMessageJob(#{message_id})" unless Rails.env.test?
    raise WaitForPrevious
  rescue => e
    msg = e.inspect.gsub(/(sk-)[\w\-]{40}/, '\1' + "*" * 40)

    unless Rails.env.test?
      Rails.logger.info "\n### Finished GetNextAIMessageJob attempt ##{attempt} with ERROR: #{msg}" unless Rails.env.test?
      Rails.logger.info e.backtrace.join("\n") if Rails.env.development?

      if attempt < 3
        GetNextAIMessageJob.broadcast_updated_message(@message, thinking: false)
        GetNextAIMessageJob.set(wait: (attempt+1).seconds).perform_later(user_id, message_id, assistant_id, attempt+1)
      else
        error_text = if e.try(:response)
          e&.response&.dig(:body, "error", "message") rescue e&.response&.dig(:body)
        else
          e.message
        end
        set_unexpected_error(msg&.slice(0...1500), error_text)
        wrap_up_the_message
      end
    end
    return false
  end

  def self.broadcast_updated_message(message, locals = {})
    html = ApplicationController.render(
      partial: "messages/message",
      locals: {
        message:,
        only_scroll_down_if_was_bottom: true,
        streamed: true,
        message_counter: message.index
      }.merge(locals)
    )
    dom = Nokogiri::HTML.fragment(html)
    html = dom.at_id(dom_id message).inner_html
    message.broadcast_update_to message.conversation, target: message, html: html
  end

  private

  def set_openai_error
    @message.content_text = "(You need to enter a valid API key for OpenAI to use GPT. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find OpenAI Key instructions.)"
  end

  def set_groq_error
    @message.content_text = "(You need to enter a valid API key for Groq to use Llama. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find Groq Key instructions.)"
  end

  def set_generic_error(name)
    @message.content_text = "(There is a configuration error with the #{name} API Service. Maybe you have an invalid API key? Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find #{name} there.)"
  end

  def set_anthropic_error
    @message.content_text = "(You need to enter a valid API key for Anthropic to use Claude. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find Anthropic Key instructions.)"
  end

  def set_response_error
    @message.content_text = "(I received a blank response. It's possible your API key is invalid, has expired, or the AI servers may be " +
      "experiencing trouble. Try again or ensure your API key is valid. You can change your API key by clicking your Profile in the bottom " +
      "left and then settings.)"
  end

  def set_unexpected_error(msg, text)
    @message.content_text = "(I received a unexpected response from the API after retrying 3 times, \"#{text}\". The AI servers may be experiencing trouble. " +
      "Try again later or if you keep getting this error ensure your API key is valid and you haven't run out of funds with your AI service.\n\n" +
      "It's also helpful if you report this to the app developers at: https://github.com/allyourbot/hostedgpt/discussions)\n\n:#{msg}"
  end

  def set_billing_error
    service = ai_backend.to_s.split("::").second
    url = case service
    when "OpenAI"
      "https://platform.openai.com/account/billing/overview"
    when "Anthropic"
      "https://console.anthropic.com/settings/plans"
    when "Gemini"
      "https://aistudio.google.com/app/apikey"
    else
      "https://platform.openai.com/account/billing/overview"
    end
    @message.content_text = "(I received a quota error. Try again and if you still get this error then your API key is probably valid, but you may need to adding billing details. You are using " +
      "#{service} so go here #{url} and add a credit card, or if you already have one review your billing plan.)"
  end

  def wrap_up_the_message
    call_tools_before_wrapping_up if @message.content_tool_calls.present? && @message.valid?

    GetNextAIMessageJob.broadcast_updated_message(@message, thinking: false)
    @message.save!
    @message.conversation.touch # updated_at change will bump it up your list + ensures it will be auto-titled

    Rails.logger.info "\n### Finished GetNextAIMessageJob.perform(#{@user.id}, #{@message.id}, #{@message.assistant_id}, #{@attempt})" unless Rails.env.test?
  end

  def call_tools_before_wrapping_up
    Rails.logger.info "\n### Calling tools" unless Rails.env.test?

    msgs = []
    Current.set(user: @user, message: @message) do
      msgs = ai_backend.get_tool_messages_by_calling(@message.content_tool_calls)
    end

    index = @message.index
    json_of_generated_image = nil
    msgs.each do |tool_message| # one message for each tool executed
      parsed = JSON.parse(tool_message[:content]) rescue nil

      if parsed.is_a?(Hash) && parsed.has_key?("json_of_generated_image")
        json_of_generated_image = parsed["json_of_generated_image"]
        # Redact the large base64 payload from the saved tool message content
        parsed = parsed.except("json_of_generated_image")
      end

      content_to_save = if parsed.is_a?(Hash)
        parsed.to_json
      else
        tool_message[:content]
      end

      @conversation.messages.create!(
        assistant: @assistant,
        role: tool_message[:role],
        content_text: content_to_save,
        tool_call_id: tool_message[:tool_call_id],
        content_tool_calls: tool_message[:content_tool_calls],
        version: @message.version,
        index: index += 1,
        processed_at: Time.current,
      )

    end

    assistant_reply = @conversation.messages.create!(
      assistant: @assistant,
      role: :assistant,
      content_text: nil,
      version: @message.version,
      index: index += 1
    )

    unless json_of_generated_image.nil?
      binary_image_contents = Base64.decode64(json_of_generated_image)

      tempfile = Tempfile.new(["generated", ".png"])
      tempfile.binmode
      tempfile.write(binary_image_contents)
      tempfile.rewind

      document = Document.new(message: assistant_reply,assistant: @assistant, user: @user, purpose: :assistants_output)
      document.file.attach(
        io: tempfile,
        filename: "generated.png",
        content_type: "image/png"
      )
      assistant_reply.documents << document

      tempfile.close
      tempfile.unlink
    end

    GetNextAIMessageJob.perform_later(
      @user.id,
      assistant_reply.id,
      @assistant.id
    ) # now AI decides what to say based on the tool responses. It may also execute more tools
  end

  def generation_was_cancelled?
    @cancel_counter = @cancel_counter.to_i + 1 # we want to skip redis on first cancel check to ensure test env runs does a second check

    message_cancelled? || newer_messages_in_conversation?
  end

  def message_cancelled?
    @message.cancelled? ||
      (@cancel_counter > 1 && @message.id == @user.reload.last_cancelled_message_id)
  end

  def newer_messages_in_conversation?
    @message != @conversation.latest_message_for_version(@message.version) ||
      (@cancel_counter > 1 && @message.id != @conversation.reload.last_assistant_message_id)
  end

  def message_is_populated?
    @message.content_text.present?
  end
end

class AIBackend
  include Utilities, Tools

  class ConfigurationError < StandardError; end

  VOICE_INSTRUCTIONS = <<~TEXT.squish
    The user is speaking to you out loud and your reply will be read aloud by a text-to-speech voice.
    Reply the way a person would talk in conversation: keep it brief, usually a few sentences, and let the user ask for more.
    Do not use markdown, bullet points, numbered lists, headings, tables, emoji, or code blocks.
    Write out anything that is awkward to hear, such as symbols, abbreviations, and URLs.
    If the user asks for code or something long, summarize it in a sentence or two and offer to type out the details.
  TEXT

  def initialize(user, assistant, conversation = nil, message = nil)
    @user = user
    @assistant = assistant
    @conversation = conversation
    @message = message # required for streaming responses
  end

  def self.test_language_model(language_model, api_name = nil)
    api_name ||= language_model.api_name
    url = language_model.api_service.url
    token = language_model.api_service.effective_token
    return "Error: API key (token) is blank" if language_model.api_service.requires_token? && token.blank?

    test_execute(url, token, api_name, driver: language_model.api_service.driver)
  end

  def self.test_api_service(api_service, url = nil, token = nil)
    url ||= api_service.url
    token ||= api_service.effective_token
    language_models = api_service.language_models.order(created_at: :desc)

    return "Error: API key (token) is blank" if api_service.requires_token? && token.blank?
    return "Error: API name is blank. Define a Language Model for this API service." if language_models.none?

    # A provider can retire a model out from under us, so don't bet the whole test on
    # whichever language model happens to be first; walk newest-first until one answers.
    result = nil
    language_models.each do |language_model|
      result = test_execute(url, token, language_model.api_name, driver: api_service.driver)
      break unless result.start_with?("Error:")
    end
    result
  end

  private

  def preceding_messages(messages = [])
    messages.map.with_index do |msg, i|
      role = (i % 2).zero? ? "user" : "assistant"

      {
        role:,
        content: msg
      }
    end
  end

  def preceding_conversation_messages
    raise NotImplementedError
  end

  def conversation_history
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).to_a
  end

  # The current time rides on the newest message the user wrote rather than in the system prompt,
  # so the instructions and the history before that message stay a stable prefix providers can cache.
  def latest_user_message(history)
    history.select(&:user?).last
  end

  # On the first message rather than the latest, so the attachments stay in the prefix providers cache.
  def documents_for(message, history)
    first_user_message = history.find(&:user?)
    return message.documents.to_a unless message == first_user_message

    @assistant.context_attachments + message.documents.to_a
  end

  def current_time_note
    "For the user, the current time is #{DateTime.current.strftime("%-l:%M%P")}; the current date is #{DateTime.current.strftime("%A, %B %-d, %Y")}"
  end

  def full_instructions
    s = @assistant.instructions.to_s

    if (memories = @user.memories.for_assistant(@assistant).pluck(:detail)).present?
      s += "\n\nNote these additional items that you've been told and remembered:\n\n"
      s += memories.join("\n")
    end

    if (context = @assistant.context_prompt).present?
      s += "\n\n#{context}"
    end

    s += "\n\n#{VOICE_INSTRUCTIONS}" if @message&.replying_to_speech?
    s.strip
  end
end

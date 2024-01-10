class ConversationAi
  class TokenLimitExceeded < StandardError; end

  MAX_TOKENS = 500
  RESPONSES_PER_NOTE = 1
  MAX_RETRIES = 1

  def initialize(user, note)
    @user = user
    @note = note
    @chat = note.chat
    @client = OpenAI::Client.new(access_token: @user.openai_key)
  end

  def process_note
    raise_if_token_limit_exceeded
    replies = create_replies
    chat_parameters = build_chat_parameters(replies)
    process_chat(chat_parameters)
    replies
  end

  private

  def create_replies
    Array.new(RESPONSES_PER_NOTE) { @note.replies.create!(content: "") }
  end

  def build_chat_parameters(replies)
    {
      model: "gpt-3.5-turbo",
      messages: prepare_messages_for_openai,
      temperature: 0.8,
      stream: handle_stream(replies),
      n: RESPONSES_PER_NOTE
    }
  end

  def process_chat(parameters)
    @client.chat(parameters: parameters)
  end

  def prepare_messages_for_openai
    @chat.notes.pluck(:content).map { |content| {role: "user", content: content} }
  end

  def handle_stream(replies)
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      finish_reason = chunk.dig("choices", 0, "finish_reason")
      reply = replies.first

      # Check if last character of reply.content and first character of
      # new_content are both numbers
      new_content = format_content(reply, new_content)

      if new_content.present?
        reply.content += new_content
        reply.broadcast_updated(new_content)
      end

      reply.save! if finish_reason.present?
    end
  end

  def format_content(reply, new_content)
    return new_content unless reply.content.present? && new_content.present?
    # Do not prepend a space if both are numbers
    return new_content if reply.content[-1].match?(/\d/) && new_content[0].match?(/\d/)
    # Prepend a space if new_content starts with a number
    return new_content unless new_content[0].match?(/\d/)

    " " + new_content
  end

  def raise_if_token_limit_exceeded
    total_count = @chat.notes.pluck(:content).sum { |msg| token_count(msg) } + MAX_TOKENS
    raise TokenLimitExceeded if total_count >= model_token_limit("gpt-3.5-turbo")
  end

  def token_count(string)
    Tiktoken.encoding_for_model("gpt-3.5-turbo").encode(string).length
  end

  def model_token_limit(name)
    {
      "gpt-4-1106-preview": 128000,
      "gpt-4-vision-preview": 128000,
      "gpt-4": 8192,
      "gpt-4-32k": 32768,
      "gpt-4-0613": 8192,
      "gpt-4-32k-0613": 32768,
      "gpt-3.5-turbo-1106": 16385,
      "gpt-3.5-turbo": 4096,
      "gpt-3.5-turbo-16k": 16385,
      "gpt-3.5-turbo-instruct": 4096
    }[name.to_sym]
  end
end

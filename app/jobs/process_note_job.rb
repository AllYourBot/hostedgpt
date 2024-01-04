class ProcessNoteJob < ApplicationJob
  class TokenLimitExceeded < StandardError; end

  QUEUE_AS = :default
  RESPONSES_PER_note = 1
  MAX_TOKENS = 500
  MAX_RETRIES = 2
  MAX_MESSAGE_LENGTH = 100000

  queue_as QUEUE_AS

  #retry_on Faraday::Error, attempts: MAX_RETRIES, wait: :exponentially_longer

  def perform(note_id, user_id)
    @user = find_user(user_id)
    @note = find_note(note_id)
    process_note_with_openai
  end

  private

  def find_user(user_id)
    User.find(user_id)
  end

  def find_note(note_id)
    Note.find(note_id)
  end

  def init_client
    @client ||= OpenAI::Client.new(access_token: @user.openai_key)
  end

  def process_note_with_openai
    init_client

    retries ||= 0
    begin
      verify_token_count!

      replies = create_and_broadcast_replies_for(@note)
      @client.chat(parameters: chat_parameters(replies))
    rescue TokenLimitExceeded => e
      handle_token_limit_exceeded
    end
  end

  def chat_parameters(replies)
    {
      model: "gpt-3.5-turbo",
      messages: format_notes_for_openai(replies),
      temperature: 0.8,
      stream: process_stream(replies),
      n: RESPONSES_PER_note
    }
  end

  def format_notes_for_openai(replies)
    user_messages = @note.chat.notes.pluck(:content)

    formatted_messages = user_messages.map do |content|
      { role: "user", content: content }
    end

    formatted_messages
  end

  def create_and_broadcast_replies_for(note)
    Array.new(RESPONSES_PER_note) do
      reply = note.replies.create!(content: "")
      reply.broadcast_created
      reply
    end
  end

  def process_stream(replies)
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

  def model_token_limit(name)
    {
        'gpt-4-1106-preview': 128000,
        'gpt-4-vision-preview': 128000,
        'gpt-4': 8192,
        'gpt-4-32k': 32768,
        'gpt-4-0613': 8192,
        'gpt-4-32k-0613': 32768,
        'gpt-3.5-turbo-1106': 16385,
        'gpt-3.5-turbo': 4096,
        'gpt-3.5-turbo-16k': 16385,
        'gpt-3.5-turbo-instruct': 4096
    }[name.to_sym]
  end

  def token_count(string, model)
    encoding = Tiktoken.encoding_for_model(model)
    encoding.encode(string).length
  end

  def verify_token_count!
    model = 'gpt-3.5-turbo'

    # Assuming @note.chat is the chat object associated with the note
    messages = @note.chat.notes.pluck(:content)
    total_count = messages.sum { |msg| token_count(msg, model) } + MAX_TOKENS
    raise TokenLimitExceeded if total_count > model_token_limit(model)
  end


  def handle_token_limit_exceeded
    Rails.logger.error "Token limit exceeded for ProcessNoteJob"
  end
end

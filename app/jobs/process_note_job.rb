class ProcessNoteJob < ApplicationJob
  QUEUE_AS = :default
  RESPONSES_PER_MESSAGE = 1

  queue_as QUEUE_AS

  def perform(note_id, user_id)
    @user = find_user(user_id)
    @note = find_note(note_id)

    configure_openai_with_user_key
    init_client

    process_note_with_openai
  end

  private

  def find_user(user_id)
    User.find(user_id)
  end

  def find_note(note_id)
    Note.find(note_id)
  end

  def configure_openai_with_user_key
    raise ArgumentError, "openai_key is missing" if @user.openai_key.blank?

    OpenAI.configure do |config|
      config.access_token = @user.openai_key
    end
  end

  def init_client
    @client ||= OpenAI::Client.new(api_key: @user.openai_key)
  end

  def process_note_with_openai
    messages = create_and_broadcast_messages_for(@note)

    @client.chat(
      parameters: chat_parameters(messages)
    )
  end

  def chat_parameters(messages)
    {
      model: "gpt-3.5-turbo",
      messages: format_messages_for_openai(messages),
      temperature: 0.8,
      stream: process_stream(messages),
      n: RESPONSES_PER_MESSAGE
    }
  end

  def format_messages_for_openai(messages)
    [@note].map { |message| { role: "user", content: message.content } }
  end

  def create_and_broadcast_messages_for(note)
    Array.new(RESPONSES_PER_MESSAGE) do
      message = note.replies.create!(content: "")
      message.broadcast_created
      message
    end
  end

  def process_stream(messages)
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      finish_reason = chunk.dig("choices", 0, "finish_reason")
      message = messages.first

      if new_content.present?
        message.content += new_content
        message.broadcast_updated
      end

      message.save! if finish_reason.present?
    end
  end
end

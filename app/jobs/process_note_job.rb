class ProcessNoteJob < ApplicationJob
  RESPONSES_PER_MESSAGE = 1

  queue_as :default

  def perform(note_id, user_id)
    @user = User.find(user_id)
    @note = Note.find(note_id)
    OpenAI.configure do |config|
      config.access_token = @user.openai_key
    end
    init_client
    call_openai!
  end

  def call_openai!
    messages = create_messages(note: @note)

    @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: for_openai(messages),
        temperature: 0.8,
        stream: stream_proc(messages),
        n: RESPONSES_PER_MESSAGE
      }
    )
  end

  def for_openai(messages)
    [@note].map { |message| { role: "user", content: message.content } }
  end

  def create_messages(note:)
    messages = []
    RESPONSES_PER_MESSAGE.times do |i|
      message = note.replies.create!(content: "")
      message.broadcast_created
      messages << message
    end
    messages
  end

  def stream_proc(messages)
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      finish_reason = chunk.dig("choices", 0, "finish_reason")
      message = messages.first

      if new_content.present?
        # update the message in memory then broadcast
        message.content += new_content
        message.broadcast_updated
      end

      if finish_reason.present?
        message.save!
      end
    end
  end

  def init_client
    raise ArgumentError, "openai_key is missing" if @user.openai_key.blank?
    @client ||= OpenAI::Client.new(api_key: @user.openai_key)
  end
end

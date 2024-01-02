class ProcessNoteJob < ApplicationJob
  QUEUE_AS = :default
  RESPONSES_PER_note = 1

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
    notes = create_and_broadcast_replies_for(@note)

    @client.chat(
      parameters: chat_parameters(notes)
    )
  end

  def chat_parameters(notes)
    {
      model: "gpt-3.5-turbo",
      messages: format_notes_for_openai(notes),
      temperature: 0.8,
      stream: process_stream(notes),
      n: RESPONSES_PER_note
    }
  end

  def format_notes_for_openai(notes)
    [@note].map { |note| { role: "user", content: note.content } }
  end

  def create_and_broadcast_replies_for(note)
    Array.new(RESPONSES_PER_note) do
      note = note.replies.create!(content: "")
      note.broadcast_created
      note
    end
  end

  def process_stream(notes)
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      finish_reason = chunk.dig("choices", 0, "finish_reason")
      note = notes.first

      if new_content.present?
        new_content += " "
        note.content += new_content
        note.broadcast_updated(new_content)
      end

      note.save! if finish_reason.present?
    end
  end
end

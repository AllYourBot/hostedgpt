class ProcessNoteJob < ApplicationJob
  QUEUE_AS = :default
  RESPONSES_PER_note = 1

  queue_as QUEUE_AS

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

    replies = create_and_broadcast_replies_for(@note)

    @client.chat(
      parameters: chat_parameters(replies)
    )
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

      # Check if last character of reply.content and first character of new_content are both numbers
      if reply.content.present? && new_content.present?
        if reply.content[-1].match?(/\d/) && new_content[0].match?(/\d/)
          # Do not prepend a space if both are numbers
        else
          # Prepend a space if new_content starts with a number
          new_content = " " + new_content if new_content[0].match?(/\d/)
        end
      end

      if new_content.present?
        reply.content += new_content
        reply.broadcast_updated(new_content)
      end

      reply.save! if finish_reason.present?
    end
  end
end

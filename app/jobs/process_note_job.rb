class ProcessNoteJob < ApplicationJob
  queue_as :default

  def perform(note_id)
    note = Note.find(note_id)
    response = openai.chat(
      parameters: {
        model: "gpt-3.5-turbo", # Required.
        messages: [{role: "user", content: note.content}], # Required.
        temperature: 0.7
      }
    )
    reply = note.replies.create!(content: response.dig("choices", 0, "message", "content"))
    reply.broadcast_created
  end

  def openai
    @client ||= OpenAI::Client.new
  end
end

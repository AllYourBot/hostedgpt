class ProcessNoteJob < ApplicationJob
  queue_as :default

  def perform(note_id, user_id)
    user = User.find(user_id)
    note = Note.find(note_id)
    response = openai(user).chat(
      parameters: {
        model: "gpt-3.5-turbo", # Required.
        messages: [{role: "user", content: note.content}], # Required.
        temperature: 0.7
      }
    )
    reply = note.replies.create!(content: response.dig("choices", 0, "message", "content"))
    reply.broadcast_created
  end

  def openai(user)
    @client ||= OpenAI::Client.new(api_key: user.openai_key)
  end
end

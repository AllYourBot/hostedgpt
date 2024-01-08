class SendNoteToOpenAiJob < ApplicationJob
  queue_as :default

  def perform(note_id, user_id)
    user = find_user(user_id)
    note = find_note(note_id)

    openai_service = ConversationAi.new(user, note)
    replies = openai_service.process_note
    broadcast_replies(replies)
  end

  private

  def find_user(user_id)
    User.find(user_id)
  end

  def find_note(note_id)
    Note.find(note_id)
  end

  def broadcast_replies(replies)
    replies.each { |reply| reply.broadcast_created }
  end
end

class ChatsController < ApplicationController
  def chat_messages_with_replies(chat_id)
    Chat.find(chat_id).messages.where(parent_id: nil).includes(:replies)
  end

  def show
    @chats = Current.user.chats
    @chat = @chats.find_by(id: params[:id]) || @chats.last
    # Fetch only those messages that are not replies
    @messages = @chat.messages.where(parent_id: nil).includes(:replies)
    @has_answered = @messages.blank?
    render "home/show"
  end
end

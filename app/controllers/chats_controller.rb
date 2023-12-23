class ChatsController < ApplicationController
  def chat_messages_with_replies(chat_id)
    Chat.find(chat_id).messages.where(parent_id: nil).includes(:replies)
  end

  def show
    @chats = Current.user.chats
    @chat = @chats.find(params[:id])
    # Fetch only those messages that are not replies
    @messages = @chat.messages.where(parent_id: nil).includes(:replies)
    @has_answered = true
    render "home/show"
  end
end

class ChatsController < ApplicationController
  def show
    # Fetch only those messages that are not replies
    @messages = current_chat.messages.where(parent_id: nil).includes(:replies)
    @has_answered = @messages.blank?
    render "home/show"
  end

  def create
    @message = current_chat.messages.new(content: params[:message_content]) # Adjust this as per your message creation logic

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(current_chat) }
      end
    else
      redirect_to dashboard_path
    end
  end

  private

  def current_chat
    @chats = Current.user.chats
    @chat ||= @chats.find_by(id: params[:id]) || @chats.last
  end
end

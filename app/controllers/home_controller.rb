class HomeController < ApplicationController
  before_action :set_chat, only: [:index, :show]

  def index
    if user_signed_in?
      render :show
    else
      render :index
    end
  end

  private

  def set_chat
    @chats = current_user.chats
    @chat = @chats.find_by(id: params[:id]) || @chats.last
    # Fetch only those messages that are not replies
    @messages = @chat && @chat.notes.where(parent_id: nil).includes(:replies)
    @has_answered = @messages.blank?
  end
end

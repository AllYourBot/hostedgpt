class ChatsController < ApplicationController
  before_action :set_chat

  def index
    if params[:content].present?
      @chat.notes.no_replies.create!(content: params[:content])
    end

    render "home/show"
  end

  def show
    render "home/show"
  end

  private

  def set_chat
    @chats = Current.user.chats
    @chat = Current.user.chats.find_by(id: params[:id]) || Current.user.chats.last
  end
end

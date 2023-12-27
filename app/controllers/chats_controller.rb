class ChatsController < ApplicationController
  before_action :set_chat

  def create
    @chat.notes.no_replies.create!(content: params[:content])
    redirect_to chat_path(@chat)
  end

  def show
    render "home/show"
  end

  private

  def set_chat
    @chats = Current.user.chats
    @chat = Current.user.chats.find_by(id: params[:id]) || Current.user.chats.last
  end

  def talk_to_openai(note)
  end
end

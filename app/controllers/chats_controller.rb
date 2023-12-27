class ChatsController < ApplicationController
  before_action :set_chat

  def show
    render "home/show"
  end

  private

  def set_chat
    @chat = Current.user.chats.find_by(id: params[:id]) || @chats.last
  end
end

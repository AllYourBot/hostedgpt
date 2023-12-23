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
    @chats = Current.user.chats.all
  end
end

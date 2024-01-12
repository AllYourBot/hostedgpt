class My::ConversationsController < ApplicationController
  def index
    @conversations = Current.user.conversations.limit(10)
  end

  def new
    @conversation = Current.user.conversations.new
  end

  def create
    @conversation = Current.user.conversations.new(conversation_params)
    if @conversation.save
      redirect_to @conversation, notice: "Conversation was successfully created."
    else
      render :new
    end
  end

  private

  def conversation_params
    params.require(:conversation).permit(:assistant_id, :title)
  end
end

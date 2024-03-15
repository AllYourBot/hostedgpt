class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:edit, :update, :destroy]
  before_action :set_nav_conversations
  before_action :set_nav_assistants

  def index
    @conversations = Current.user.conversations
  end

  def edit
  end

  def new
    @conversation = Current.user.conversations.new
  end

  def create
    @conversation = Current.user.conversations.new(conversation_params)

    if @conversation.save
      redirect_to @conversation, notice: "Conversation was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @conversation.update(conversation_params)
      redirect_to @conversation, notice: "Conversation was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation.destroy!
    redirect_to conversations_url, notice: "Conversation was successfully destroyed.", status: :see_other
  end

  private

  def set_nav_conversations
    @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user)
  end

  def set_nav_assistants
    @nav_assistants = Current.user.assistants.ordered
  end

  def set_conversation
    @conversation = Current.user.conversations.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:user_id, :assistant_id, :title)
  end
end

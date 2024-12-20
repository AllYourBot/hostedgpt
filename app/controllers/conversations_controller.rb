class ConversationsController < ApplicationController
  before_action :set_conversation
  before_action :set_nav_assistants

  def index
    @query = params[:query]
    @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user, @query)
  end

  def show
  end

  def edit
  end

  def update
    if @conversation.update(conversation_params)
      redirect_to @conversation, status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation.destroy!
    if request.referer && request.referer.starts_with?(conversation_messages_url(@conversation))
      redirect_to root_path, notice: "Deleted conversation", status: :see_other
    else
      redirect_back fallback_location: root_path, notice: "Deleted conversation", status: :see_other
    end
  end

  private

  def set_nav_assistants
    @nav_assistants = Current.user.assistants.ordered
  end

  def set_conversation
    @conversation = Current.user.conversations.find_by(id: params[:id] || params[:conversation_id])
  end

  def conversation_params
    params.require(:conversation).permit(:user_id, :assistant_id, :title)
  end
end

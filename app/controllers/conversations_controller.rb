class ConversationsController < ApplicationController
  before_action :set_conversation, except: [:public_show]
  before_action :set_nav_assistants, except: [:public_show]
  allow_unauthenticated_access only: [:public_show]

  def index
    @query = params[:query]
    searching = @query.present?

    # Search results are one flat list of matches, so while searching a pinned conversation shows up
    # in its time group like any other instead of being pulled out into the Pinned section.
    @pinned_conversations = searching ? [] : Current.user.conversations.pinned.to_a
    @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user, @query, exclude_pinned: !searching)
  end

  def show
  end

  def edit
  end

  def update
    if @conversation.update(conversation_params)
      redirect_to @conversation, status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @conversation.destroy!
    if request.referer && request.referer.starts_with?(conversation_messages_url(@conversation))
      redirect_to root_path, notice: I18n.t("app.flashes.conversations.deleted"), status: :see_other
    else
      redirect_back fallback_location: root_path, notice: I18n.t("app.flashes.conversations.deleted"), status: :see_other
    end
  end

  def reorder
    Current.user.conversations.reposition(params[:ids] || [])
    head :no_content
  end

  def public_show
    @conversation = Conversation.find_by!(share_token: params[:share_token])
    @messages = @conversation.messages.includes(:assistant).ordered
    @assistant = @conversation.assistant
    render "public_show", layout: "public"
  end

  private

  def set_conversation
    @conversation = Current.user.conversations.find_by(id: params[:id] || params[:conversation_id])
  end

  def conversation_params = params.require(:conversation).permit(:user_id, :assistant_id, :title)
end

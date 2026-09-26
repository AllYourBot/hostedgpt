class ConversationsController < ApplicationController
  before_action :set_conversation, except: [:public_show, :reorder]
  before_action :set_nav_assistants, except: [:public_show]
  allow_unauthenticated_access only: [:public_show]

  def index
    @query = params[:query]
    @pinned_conversations = Conversation.pinned_nav_for_user(Current.user, @query)
    @nav_conversations = Conversation.nav_for_user(Current.user, @query)
  end

  # The bookmarks view reuses the index template with a bookmark filter: exactly the user's
  # bookmarked conversations in display order (pins are not split out here), narrowed by the
  # search query when one is present. No pinned section — a partial pin list must never expose
  # drag, same rationale as the filtered-list guard.
  def bookmarks
    @query = params[:query]
    @bookmarks_view = true
    @pinned_conversations = Conversation.none
    @nav_conversations = Conversation.bookmarked_nav_for_user(Current.user, @query)
    render :index
  end

  def reorder
    Conversation.reposition(Current.user, Array(params[:ids]))
    head :no_content
  end

  def pin
    @conversation&.pin!(Current.user)
    head :no_content
  end

  def unpin
    @conversation&.unpin!(Current.user)
    head :no_content
  end

  def bookmark
    @conversation&.bookmark!(Current.user)
    head :no_content
  end

  def unbookmark
    @conversation&.unbookmark!(Current.user)
    head :no_content
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

  def conversation_params
    params.require(:conversation).permit(:user_id, :assistant_id, :title)
  end
end

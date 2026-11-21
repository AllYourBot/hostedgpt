class ConversationsController < ApplicationController
  include SidebarRefreshable

  before_action :set_conversation, except: [:public_show, :bookmark, :unbookmark, :bookmarked_page]
  before_action :set_toggled_conversation, only: [:bookmark, :unbookmark]
  before_action :set_nav_assistants, except: [:public_show, :bookmark, :unbookmark]
  allow_unauthenticated_access only: [:public_show]

  def index
    set_nav_conversations
  end

  def bookmarked_page
    @bookmarked_conversations = Current.user.bookmarks
      .where(bookmarkable_type: "Conversation")
      .order(created_at: :desc, id: :desc)
      .preload(:bookmarkable)
    @bookmarked_messages = Current.user.bookmarks
      .where(bookmarkable_type: "Message")
      .order(created_at: :desc, id: :desc)
      .preload(bookmarkable: [:bookmarks, :assistant, {conversation: :user}])
  end

  def bookmark
    @toggled_conversation.bookmark!(Current.user)
    render_sidebar(toggled_conversation: @toggled_conversation)
  end

  def unbookmark
    # The entry element is identified before the row is destroyed so the response can remove it in place.
    entry = Current.user.bookmarks.find_by(bookmarkable: @toggled_conversation) if params[:from_bookmarks]
    @toggled_conversation.unbookmark!(Current.user)
    render_sidebar(entry_to_remove: entry, page_context: params[:from_bookmarks].present?, toggled_conversation: @toggled_conversation)
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

  # find (not find_by): someone else's conversation, or a missing one, is a 404 — the pins
  # controller precedent. Toggle endpoints never silently no-op.
  def set_toggled_conversation
    @toggled_conversation = Current.user.conversations.find(params[:id])
    # Keep the viewed conversation highlighted when the toggle re-renders the nav.
    @conversation = @toggled_conversation
  end

  def conversation_params = params.require(:conversation).permit(:user_id, :assistant_id, :title)
end

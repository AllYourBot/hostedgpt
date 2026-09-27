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

  # The reactions view reuses the index template with a reaction filter: every conversation the
  # user reacted to — directly or on one of its messages — newest touching reaction first (pins
  # are not split out here), narrowed by the search query when one is present. No pinned
  # section — a partial pin list must never expose drag, same rationale as the filtered-list
  # guard.
  def reactions
    @query = params[:query]
    @reactions_view = true
    @pinned_conversations = Conversation.none
    @nav_conversations = Conversation.reacted_nav_for_user(Current.user, @query)
    render :index
  end

  # Hand order lives only in the pinned section, so only pinned ids are renumbered: a subset
  # post (stale JS, replayed fetch, curl) can never overwrite the untouched remainder.
  def reorder
    pinned_ids = Current.user.conversations.pinned_for(Current.user).pluck(:id)
    Conversation.reposition(Current.user, Array(params[:ids]).map(&:to_i) & pinned_ids)
    head :no_content
  end

  def pin
    @conversation&.pin!(Current.user)
    render_sidebar
  end

  def unpin
    @conversation&.unpin!(Current.user)
    render_sidebar
  end

  def bookmark
    @conversation&.bookmark!(Current.user)
    render_sidebar
  end

  def unbookmark
    @conversation&.unbookmark!(Current.user)
    render_sidebar
  end

  def react
    @conversation&.react!(params[:emoji], Current.user)
    head :no_content
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_content
  end

  def unreact
    @conversation&.unreact!(params[:emoji], Current.user)
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

  # Sidebar toggles answer with the re-rendered nav frame, not a page refresh: the response
  # morphs exactly the list the user is looking at (main, bookmarks, reactions, or search, per
  # the bounced-back view params), so icons flip and rows move with no reload and no scroll
  # loss. Plain requests still answer 204.
  def render_sidebar
    @query = params[:query]
    @bookmarks_view = params[:nav_view] == "bookmarks"
    @reactions_view = params[:nav_view] == "reactions"
    if @bookmarks_view
      @pinned_conversations = Conversation.none
      @nav_conversations = Conversation.bookmarked_nav_for_user(Current.user, @query)
    elsif @reactions_view
      @pinned_conversations = Conversation.none
      @nav_conversations = Conversation.reacted_nav_for_user(Current.user, @query)
    else
      @pinned_conversations = Conversation.pinned_nav_for_user(Current.user, @query)
      @nav_conversations = Conversation.nav_for_user(Current.user, @query)
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("nav-conversations", partial: "conversations/nav") }
      format.html { head :no_content }
    end
  end

  def set_conversation
    @conversation = Current.user.conversations.find_by(id: params[:id] || params[:conversation_id])
  end

  def conversation_params
    params.require(:conversation).permit(:user_id, :assistant_id, :title)
  end
end

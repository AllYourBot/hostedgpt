class ConversationsController < ApplicationController
  before_action :set_conversation, except: [:public_show, :bookmark, :unbookmark, :bookmarked_page]
  before_action :set_toggled_conversation, only: [:bookmark, :unbookmark]
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

  def bookmarked_page
    # One retrieval surface for both target types (KD4): each section lists the user's own
    # bookmarks, most recently bookmarked first. Bookmarks whose target no longer resolves
    # are skipped by the entry partials, not here — the preload already paid for the load.
    @bookmarked_conversations = Current.user.bookmarks
      .where(bookmarkable_type: "Conversation")
      .order(created_at: :desc, id: :desc)
      .preload(:bookmarkable)
    @bookmarked_messages = Current.user.bookmarks
      .where(bookmarkable_type: "Message")
      .order(created_at: :desc, id: :desc)
      .preload(:bookmarkable)
  end

  def bookmark
    @toggled_conversation.bookmark!(Current.user)
    render_sidebar
  end

  def unbookmark
    # Page-context forms mark themselves with from_bookmarks: their entry element is
    # identified before the row is destroyed so the response can remove it in place.
    entry = Current.user.bookmarks.find_by(bookmarkable: @toggled_conversation) if params[:from_bookmarks]
    @toggled_conversation.unbookmark!(Current.user)
    render_sidebar(entry_to_remove: entry)
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
  end

  # Sidebar toggles answer with the re-rendered nav frame, not a page refresh: the response
  # morphs exactly the list the user is looking at (search included, per the bounced-back
  # query), so the icon flips with no reload and no scroll loss. Page-context unbookmarks
  # (the /bookmarks page, marked from_bookmarks) first remove their list entry, then refresh
  # the nav frame so the sidebar's icon un-flips too. Autofocus is suppressed so a toggle
  # never steals focus, and plain requests still answer 204.
  def render_sidebar(entry_to_remove: nil)
    @query = params[:query]
    @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user, @query)

    respond_to do |format|
      format.turbo_stream do
        streams = []
        streams << turbo_stream.remove(helpers.dom_id(entry_to_remove)) if entry_to_remove
        streams << turbo_stream.update("nav-conversations", partial: "conversations/nav", locals: {autofocus: false})
        render turbo_stream: streams
      end
      format.html { head :no_content }
    end
  end

  def conversation_params = params.require(:conversation).permit(:user_id, :assistant_id, :title)
end

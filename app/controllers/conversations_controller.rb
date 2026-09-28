class ConversationsController < ApplicationController
  before_action :set_conversation, except: [:public_show, :reorder]
  before_action :set_nav_assistants, except: [:public_show]
  # The card pages render the shared sidebar shell, which now carries upstream's
  # collections section — it needs @nav_collections like every other controller
  # that renders the shell.
  before_action :set_nav_collections, only: [:pinned_page, :bookmarked_page, :reacted_page]
  allow_unauthenticated_access only: [:public_show]

  def index
    @query = params[:query]
    @show = funnel_show
    assign_sidebar_lists
  end

  # The bookmarks view reuses the index template with a bookmark filter: exactly the user's
  # bookmarked conversations in display order (pins are not split out here), narrowed by the
  # search query when one is present. No pinned section — a partial pin list must never expose
  # drag, same rationale as the filtered-list guard. Legacy entry to the funnel (KTD8/R13):
  # forces the same @show state the funnel menu sets, so one mechanism serves both.
  def bookmarks
    @query = params[:query]
    @show = "bookmarked"
    assign_sidebar_lists
    render :index
  end

  # The reactions view reuses the index template with a reaction filter: every conversation the
  # user reacted to — directly or on one of its messages — newest touching reaction first (pins
  # are not split out here), narrowed by the search query when one is present. No pinned
  # section — a partial pin list must never expose drag, same rationale as the filtered-list
  # guard. Legacy entry to the funnel (KTD8/R13): same @show state as the funnel menu.
  def reactions
    @query = params[:query]
    @show = "reacted"
    assign_sidebar_lists
    render :index
  end

  # Full card pages mirroring assistants#index: each collection renders as Assistant-style
  # cards in the main column (nav_column still supplies the sidebar). Scopes are the same
  # nav scopes the sidebar filtered views use, so ordering and isolation match.
  def pinned_page
    @page_context = "pinned"
    @pinned_conversations = Conversation.pinned_nav_for_user(Current.user)
  end

  def bookmarked_page
    @page_context = "bookmarked"
    @bookmarked_conversations = Conversation.bookmarked_nav_for_user(Current.user)
  end

  def reacted_page
    @page_context = "reacted"
    @reacted_conversations = Conversation.reacted_nav_for_user(Current.user)
  end

  # Hand order lives only in the pinned section, so only pinned ids are renumbered: a subset
  # post (stale JS, replayed fetch, curl) can never overwrite the untouched remainder. Answers
  # the re-rendered sidebar to stream requests so drags land on server truth with no reload.
  def reorder
    pinned_ids = Current.user.conversations.pinned_for(Current.user).pluck(:id)
    Conversation.reposition(Current.user, Array(params[:ids]).map(&:to_i) & pinned_ids)
    render_sidebar
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
  # loss. Card-page toggles (page_context bounced back from _conversation_card) answer a
  # card-replacement stream instead: the grid updates without reload, mirroring the sidebar
  # morph contract. Plain requests still answer 204. Funnel scope (show, plus legacy
  # nav_view) bounces back the same way so toggles never reset an active filter.
  def render_sidebar
    return render_card_toggle if params[:page_context].in?(%w[pinned bookmarked reacted])

    @query = params[:query]
    @show = funnel_show
    assign_sidebar_lists

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("nav-conversations", partial: "conversations/nav") }
      format.html { head :no_content }
    end
  end

  # Funnel state (U9 minimal slice, KTD6-KTD8). Canonical Show scope for the sidebar filter:
  # the explicit show param wins, legacy nav_view maps onto it, legacy routes force it in
  # their actions. No persistence — scope lives in frame params/query and resets on reload
  # (R14). No Show-Pinned scope: the pinned strip covers that surface (R9).
  def funnel_show
    show = params[:show].to_s
    return show if %w[all bookmarked reacted].include?(show)

    case params[:nav_view].to_s
    when "bookmarks" then "bookmarked"
    when "reactions" then "reacted"
    else "all"
    end
  end

  # Single scope-plumbing choke point for index/bookmarks/reactions/render_sidebar (KTD8):
  # reuses bookmarked_nav_for_user/reacted_nav_for_user/pinned_nav_for_user unchanged.
  # Strip suppression and the flat-list guard keep reading @bookmarks_view/@reactions_view,
  # which mirror @show, so filtered scopes stay flat, undraggable, and strip-free (R11).
  # Once-visible rule (R12/AE7): under an exclusive filter, params[:new_id] prepends one
  # unmarked conversation without clearing scope; the param is transient so a reload drops
  # it and the scope resets (R14).
  def assign_sidebar_lists
    @bookmarks_view = (@show == "bookmarked")
    @reactions_view = (@show == "reacted")

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

    new_id = params[:new_id].presence
    return if new_id.nil? || @show == "all"

    # Same toggle preloads as every sibling row: the partial reads pinned?,
    # bookmarked?, assistant, and reaction counts per row, which fall back to a
    # query each when the preloaded cache is missing.
    fresh = Current.user.conversations.preload(:assistant, :pins, :bookmarks, :reactions).find_by(id: new_id)
    return if fresh.nil?
    return if @nav_conversations.map(&:id).include?(fresh.id)

    @nav_conversations = [fresh] + @nav_conversations.to_a
  end

  def set_conversation
    @conversation = Current.user.conversations.find_by(id: params[:id] || params[:conversation_id])
  end

  # Card toggles replace (or remove) the card's dom-id so the grid on /pinned, /bookmarks,
  # and /reactions updates without reload. Removal applies when the toggle drops the
  # conversation out of the page's own collection (unpin on pinned, unbookmark on
  # bookmarked); every other toggle keeps the card and flips its icons in place. Pin and
  # bookmark never disturb reacted membership, so reacted cards always replace.
  def render_card_toggle
    @page_context = params[:page_context]
    return head :no_content if @conversation.nil?

    @conversation.reload
    card_id = view_context.dom_id(@conversation, :card)
    still_member = case @page_context
    when "pinned" then @conversation.pinned?(Current.user)
    when "bookmarked" then @conversation.bookmarked?(Current.user)
    else true
    end

    respond_to do |format|
      format.turbo_stream do
        if still_member
          render turbo_stream: turbo_stream.replace(
            card_id,
            partial: "conversations/conversation_card",
            locals: { conversation: @conversation, page_context: @page_context }
          )
        else
          render turbo_stream: turbo_stream.remove(card_id)
        end
      end
      format.html { head :no_content }
    end
  end

  def conversation_params
    params.require(:conversation).permit(:user_id, :assistant_id, :title)
  end
end

# Shared by the conversations and messages controllers: bookmark and other sidebar toggles
# answer with a turbo-stream re-render of the sidebar's nav frame instead of a page refresh.
module SidebarRefreshable
  extend ActiveSupport::Concern

  # The response morphs exactly the list the user is looking at (search included, per the
  # bounced-back query), so the icon flips with no reload and no scroll loss. Page-context
  # unbookmarks (the /bookmarks page, marked from_bookmarks) first remove their list entry,
  # then refresh the nav frame so the sidebar's icon un-flips too. Autofocus is suppressed
  # so a toggle never steals focus, and plain requests answer 204. A conversation toggle
  # additionally flips the chat header's stateful bookmark control: the targets are scoped
  # to the toggled conversation — a foreign toggle matches nothing — and split by variant,
  # because the wide header labels the control and the narrow one doesn't.
  def render_sidebar(entry_to_remove: nil, page_context: false, toggled_conversation: nil)
    respond_to do |format|
      format.turbo_stream do
        set_nav_conversations

        streams = []
        if page_context && entry_to_remove.nil?
          # The entry is already gone server-side (stale second tab): converge the page.
          streams << turbo_stream.refresh
        else
          streams << turbo_stream.remove(helpers.dom_id(entry_to_remove)) if entry_to_remove
          streams << turbo_stream.update("nav-conversations", partial: "conversations/nav", locals: {autofocus: false})
        end
        if toggled_conversation
          streams << header_bookmark_stream(toggled_conversation, labeled: true)
          streams << header_bookmark_stream(toggled_conversation, labeled: false)
        end
        render turbo_stream: streams
      end
      format.html { head :no_content }
    end
  end

  private

  def header_bookmark_stream(conversation, labeled:)
    turbo_stream.update_all(
      "[data-conversation-bookmark-toggle#{labeled ? "-labeled" : ""}='#{conversation.id}']",
      partial: "messages/main_column/bookmarks_toggle",
      locals: {conversation: conversation, show_label: labeled}
    )
  end

  # The nav's data, shared by index and the toggle re-renders: while searching, results are one
  # flat list of matches, so a pinned conversation shows up in its time group like any other
  # instead of being pulled out into the Pinned section.
  def set_nav_conversations
    @query = params[:query]
    searching = @query.present?
    @pinned_conversations = searching ? [] : Current.user.conversations.pinned.to_a
    @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user, @query, exclude_pinned: !searching)
  end
end

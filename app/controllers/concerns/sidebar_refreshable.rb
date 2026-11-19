# Shared by the conversations and messages controllers: bookmark and other sidebar toggles
# answer with a turbo-stream re-render of the sidebar's nav frame instead of a page refresh.
module SidebarRefreshable
  extend ActiveSupport::Concern

  # The response morphs exactly the list the user is looking at (search included, per the
  # bounced-back query), so the icon flips with no reload and no scroll loss. Page-context
  # unbookmarks (the /bookmarks page, marked from_bookmarks) first remove their list entry,
  # then refresh the nav frame so the sidebar's icon un-flips too. Autofocus is suppressed
  # so a toggle never steals focus, and plain requests answer 204.
  def render_sidebar(entry_to_remove: nil, page_context: false)
    respond_to do |format|
      format.turbo_stream do
        @query = params[:query]
        @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user, @query)

        streams = []
        if page_context && entry_to_remove.nil?
          # The entry is already gone server-side (stale second tab): converge the page.
          streams << turbo_stream.refresh
        else
          streams << turbo_stream.remove(helpers.dom_id(entry_to_remove)) if entry_to_remove
          streams << turbo_stream.update("nav-conversations", partial: "conversations/nav", locals: {autofocus: false})
        end
        render turbo_stream: streams
      end
      format.html { head :no_content }
    end
  end
end

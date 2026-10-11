module Bookmarkable
  extend ActiveSupport::Concern

  included do
    # Plain polymorphic membership, owned by the conversation: conversations are hard-deleted, so
    # bookmarks cascade with an explicit destroy rather than lingering.
    has_many :bookmarks, as: :bookmarkable, dependent: :destroy

    # Membership only — bookmarks carry no hand order, so this scope is unordered by design and
    # callers read it through display order (see Conversation.bookmarked_nav_for_user).
    scope :bookmarked_for, ->(user) { joins(:bookmarks).where(bookmarks: { user: user }) }
  end

  # Membership only — no position change, so toggling never disturbs sidebar order (unlike pin!).
  # The find runs first so double bookmarks never touch the database twice; the RecordNotUnique
  # rescue covers the concurrent-insert window.
  def bookmark!(bookmarking_user = user)
    begin
      bookmarks.find_or_create_by!(user: bookmarking_user)
    rescue ActiveRecord::RecordNotUnique
      bookmarks.find_by!(user: bookmarking_user)
    end
  end

  def unbookmark!(bookmarking_user = user)
    bookmarks.where(user: bookmarking_user).destroy_all
  end

  def bookmarked?(bookmarking_user = user)
    # Reads the preloaded membership when the sidebar already loaded it, so rows render with no
    # per-row query; falls back to the exists? check everywhere else. Same answer either way.
    if bookmarks.loaded?
      bookmarks.any? { |bookmark| bookmark.user_id == bookmarking_user&.id }
    else
      bookmarks.exists?(user: bookmarking_user)
    end
  end
end

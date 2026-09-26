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
  # Find-or-create makes a double bookmark a no-op.
  def bookmark!(bookmarking_user = user)
    bookmarks.find_or_create_by!(user: bookmarking_user)
  end

  # Membership only — unbookmarking a clear conversation destroys nothing.
  def unbookmark!(bookmarking_user = user)
    bookmarks.where(user: bookmarking_user).destroy_all
  end

  def bookmarked?(bookmarking_user = user)
    bookmarks.exists?(user: bookmarking_user)
  end
end

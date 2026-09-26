module Reactable
  extend ActiveSupport::Concern

  included do
    # Plain polymorphic membership, owned by the record: conversations and messages are
    # hard-deleted, so reactions cascade with an explicit destroy rather than lingering.
    has_many :reactions, as: :reactable, dependent: :destroy

    # Membership only — reactions carry no hand order, so this scope is unordered by design and
    # callers read it through display order (see Conversation.reacted_nav_for_user).
    scope :reacted_for, ->(user) { joins(:reactions).where(reactions: { user: user }) }
  end

  # Membership only — no position change, so toggling never disturbs sidebar order (unlike pin!).
  # Find-or-create makes a double react a no-op. Blank emoji is rejected by the model validation.
  def react!(emoji, reacting_user = user)
    reactions.find_or_create_by!(user: reacting_user, emoji: emoji)
  end

  # Membership only — unreacting a clear emoji destroys nothing.
  def unreact!(emoji, reacting_user = user)
    reactions.where(user: reacting_user, emoji: emoji).destroy_all
  end

  def user_reacted?(emoji, reacting_user = user)
    # Reads the preloaded membership when the sidebar already loaded it, so rows render with no
    # per-row query; falls back to the exists? check everywhere else. Same answer either way.
    if reactions.loaded?
      reactions.any? { |reaction| reaction.user_id == reacting_user&.id && reaction.emoji == emoji }
    else
      reactions.exists?(user: reacting_user, emoji: emoji)
    end
  end

  # Counts grouped by emoji, e.g. { "👍" => 2, "🎉" => 1 } — what the row and message chips render.
  def reaction_counts
    # Tallies the preloaded membership when the sidebar already loaded it, so rows render with
    # no per-row query; falls back to the grouped count everywhere else. Same answer either way.
    if reactions.loaded?
      reactions.group_by(&:emoji).transform_values(&:count)
    else
      reactions.group(:emoji).count
    end
  end
end

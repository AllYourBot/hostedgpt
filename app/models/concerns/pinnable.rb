module Pinnable
  extend ActiveSupport::Concern

  included do
    # Plain polymorphic membership, owned by the conversation: conversations are hard-deleted, so
    # pins cascade with an explicit destroy rather than lingering.
    has_many :pins, as: :pinnable, dependent: :destroy

    # The pinned section for a user, in hand order (conversations.position). Unpinned reads
    # ignore position entirely — no position column lives on pins.
    scope :pinned_for, ->(user) { joins(:pins).where(pins: { user: user }).ordered }
    scope :unpinned_for, ->(user) { where.not(id: pinned_for(user).select(:id)) }
  end

  # Claims the top position slot, mirroring Reorderable#assign_default_position: the minimum
  # over the owner's collection minus one. update_column keeps updated_at untouched so pinning
  # never disturbs recency. Find-or-create makes a double pin a no-op on membership; it still
  # re-claims the top, which is what re-pinning means.
  def pin!(pinning_user = user)
    pins.find_or_create_by!(user: pinning_user)
    update_column(:position, (self.class.reorder_scope(user).minimum(:position) || 0) - 1)
  end

  # Membership only — the position value stays where pinning left it.
  def unpin!(pinning_user = user)
    pins.where(user: pinning_user).destroy_all
  end

  def pinned?(pinning_user = user)
    pins.exists?(user: pinning_user)
  end
end

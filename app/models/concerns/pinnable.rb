module Pinnable
  extend ActiveSupport::Concern

  included do
    # Plain polymorphic membership, shared by every pinnable (conversations and messages ride
    # the same pins table, told apart by pinnable_type — no new migration). Conversations are
    # hard-deleted, so pins cascade with an explicit destroy rather than lingering.
    has_many :pins, as: :pinnable, dependent: :destroy

    # The pinned section for a user. Models with hand order (a position column, i.e.
    # conversations) render in that order; models without one (messages) carry no hand
    # order, so membership is unordered by design and callers read it through display order.
    scope :pinned_for, ->(user) {
      scope = joins(:pins).where(pins: { user: user })
      scope = scope.ordered if column_names.include?("position")
      scope
    }
    scope :unpinned_for, ->(user) { where.not(id: pinned_for(user).select(:id)) }
  end

  # Membership plus, on position-bearing models only, the top position slot claim mirroring
  # Reorderable#assign_default_position: the minimum over the owner's collection minus one.
  # update_column keeps updated_at untouched so pinning never disturbs recency. Find-or-create
  # makes a double pin a no-op on membership; on conversations it still re-claims the top,
  # which is what re-pinning means. Messages have no position column and no Reorderable, so
  # their pins are membership only — the guard keeps one concern serving both.
  def pin!(pinning_user = user)
    pins.find_or_create_by!(user: pinning_user)
    update_column(:position, (self.class.reorder_scope(user).minimum(:position) || 0) - 1) if position_bearing?
  end

  # Membership only — the position value stays where pinning left it.
  def unpin!(pinning_user = user)
    pins.where(user: pinning_user).destroy_all
  end

  def pinned?(pinning_user = user)
    # Reads the preloaded membership when the sidebar already loaded it, so rows render with no
    # per-row query; falls back to the exists? check everywhere else. Same answer either way.
    if pins.loaded?
      pins.any? { |pin| pin.user_id == pinning_user&.id }
    else
      pins.exists?(user: pinning_user)
    end
  end

  private

  # Only conversations bear hand order: they have the position column and Reorderable's
  # reorder_scope. Messages have neither, so pin! skips the top-slot claim for them.
  def position_bearing?
    respond_to?(:position) && self.class.respond_to?(:reorder_scope)
  end
end

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
  # update_column keeps updated_at untouched so pinning never disturbs recency. The find runs
  # first so double pins never touch the database twice; the RecordNotUnique rescue covers the
  # concurrent-insert window (create_or_find_by is no help here — the uniqueness validation
  # rejects existing rows before any INSERT runs). An already-pinned record skips the claim,
  # so double pins are fully idempotent and the minimum never drifts. The claim takes the same
  # user-row lock as assign_default_position, so concurrent pins cannot tie for the top slot.
  def pin!(pinning_user = user)
    already_pinned = pins.exists?(user: pinning_user)
    begin
      pins.find_or_create_by!(user: pinning_user)
    rescue ActiveRecord::RecordNotUnique
      pins.find_by!(user: pinning_user)
    end
    claim_top_position unless already_pinned || !position_bearing?
  end

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

  def claim_top_position
    user.class.transaction do
      user.class.where(id: user.id).lock.pick(:id)
      update_column(:position, (self.class.reorder_scope(user).minimum(:position) || 0) - 1)
    end
  end
end

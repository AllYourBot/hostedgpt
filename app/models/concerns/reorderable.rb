module Reorderable
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(:position, id: :desc) }

    # The collection a record's position lives in, scoped to one user. Models override it when
    # their ordering spans more than the plain association — Assistant includes soft-deleted
    # records because they keep holding places in the list.
    scope :reorder_scope, ->(user) { where(user: user) }

    before_create :assign_default_position
  end

  # Request ids normalized once for every caller: plain arrays pass through, a missing
  # param becomes empty, and non-scalar junk (a crafted hash param, symbols) is dropped
  # instead of raising — it must ignore its way out, never 500.
  def self.normalize_ids(ids)
    Array(ids).flatten.filter_map { |v| v.to_s.to_i if v.is_a?(String) || v.is_a?(Numeric) }.uniq
  end

  # Renumbers the records named by ids, in the order posted, densely from zero — which is
  # how the sidebar hands back a list the user has dragged into shape. The user is part of
  # the call on purpose: the renumbering is confined to reorder_scope(user), so no caller —
  # however lazy — can renumber anyone else's records. Ids outside that scope are ignored
  # and consume no slot. Callers pass the complete ordered set for their list (each reorder
  # action completes a partial post against its own universe first), so untouched records
  # simply are not named here.
  class_methods do
    def reposition(user, ids)
      ids = Reorderable.normalize_ids(ids)
      records = reorder_scope(user).where(id: ids).index_by(&:id)

      transaction do
        ids.filter_map { |id| records[id] }.each_with_index do |record, index|
          record.update_column(:position, index)
        end
      end
    end
  end

  # Moves this record to a slot in the list, shifting the siblings it passes to make room.
  def insert_at(new_position)
    return if position == new_position

    siblings = self.class.reorder_scope(user).ordered
    if position.nil?
      # Claiming a first slot: everything from the target down slides to make room.
      siblings.where(position: new_position..).update_all("position = position + 1")
    elsif position > new_position
      # Moving up: the records between the target and the old slot slide down one.
      siblings.where(position: new_position...position).update_all("position = position + 1")
    else
      # Moving down: the records between the old slot and the target slide up one.
      siblings.where(position: (position + 1)..new_position).update_all("position = position - 1")
    end

    update_column(:position, new_position)
  end

  private

  # A new record belongs at the top of the list, which is where it landed back when the list was
  # ordered newest-first. The lock is what keeps the top honest: two records created in the same
  # instant would otherwise both read the same minimum and tie for the same slot. Holding the
  # user's row until the insert commits queues one user's creates behind each other, so each one
  # reads a minimum that includes the record the last one just claimed — every slot unique.
  #
  # The lock is taken with a bare FOR UPDATE select rather than user.lock!, because lock! reloads
  # the user in place — and a reload mid-save throws away the record's in-flight nested state
  # (a credential built through nested attributes has not been inserted yet, and the reload
  # erases it from the association before autosave reaches it).
  def assign_default_position
    self.position ||= user.class.transaction do
      user.class.where(id: user.id).lock.pick(:id)
      (self.class.reorder_scope(user).minimum(:position) || 0) - 1
    end
  end
end

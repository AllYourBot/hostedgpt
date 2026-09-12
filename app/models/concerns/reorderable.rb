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

  # Renumbers this collection to match the order of ids, which is how the sidebar hands back a list
  # the user has dragged into shape. Ids the collection does not contain are simply ignored, so a
  # user-scoped relation cannot be talked into reordering someone else's records.
  class_methods do
    def reposition(ids)
      ids = ids.map(&:to_i)

      transaction do
        where(id: ids).each { |record| record.update_column(:position, ids.index(record.id)) }
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
  # ordered newest-first.
  def assign_default_position
    self.position ||= (self.class.reorder_scope(user).minimum(:position) || 0) - 1
  end
end
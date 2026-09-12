module Reorderable
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(:position, id: :desc) }
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
end
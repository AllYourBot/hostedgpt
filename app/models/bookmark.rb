class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true

  # One bookmark per (user, target); the unique index is the race-safe guard, this is the friendly one.
  validates :user_id, uniqueness: { scope: %i[bookmarkable_type bookmarkable_id] }
end

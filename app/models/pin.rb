class Pin < ApplicationRecord
  belongs_to :user
  belongs_to :pinnable, polymorphic: true

  # One pin per (user, target); the unique index is the race-safe guard, this is the friendly one.
  validates :user_id, uniqueness: { scope: %i[pinnable_type pinnable_id] }
end

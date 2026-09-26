class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :reactable, polymorphic: true

  validates :emoji, presence: true

  # One reaction per (user, target, emoji); the unique index is the race-safe guard, this is the friendly one.
  validates :user_id, uniqueness: { scope: %i[reactable_type reactable_id emoji] }
end

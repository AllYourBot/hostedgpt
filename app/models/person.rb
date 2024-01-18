class Person < ApplicationRecord
  delegated_type :personable, types: %w[User Tombstone]
  validates_associated :personable

  validates :email, presence: true, uniqueness: true
end

class Person < ApplicationRecord
  encrypts :email, deterministic: true

  delegated_type :personable, types: %w[User Tombstone]
  accepts_nested_attributes_for :personable

  validate :personable_id_unchanged, on: :update
  validates_associated :personable
  validates :email, email: true, presence: true, uniqueness: true
  validates :uid, uniqueness: true, allow_nil: true
  validate :proper_personable_id, on: :update

  scope :ordered, -> { order(:created_at) }

  normalizes :email, with: -> email { email.downcase.strip }

  private

  def personable_id_unchanged
    if personable_id_changed? && persisted?
      errors.add(:personable_id, "cannot be changed after creation")
    end
  end

  def proper_personable_id
    if personable.id.blank?
      errors.add(:personable_id, 'must be provided on update')
    end
  end
end

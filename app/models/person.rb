class Person < ApplicationRecord
  delegated_type :personable, types: %w[User Tombstone]
  accepts_nested_attributes_for :personable

  validate :personable_id_unchanged, on: :update
  validates_associated :personable
  validates :email, presence: true, uniqueness: true
  validate :proper_personable_id, on: :update

  scope :ordered, -> { order(:created_at) }

  def email=(email)
    super(email.strip.downcase)
  end

  private

  def personable_id_unchanged
    if personable_id_changed? && persisted?
      errors.add(:personable_id, "cannot be changed after creation")
    end
  end

  def proper_personable_id
    if personable.id.blank?
      errors.add(:personable_id, 'must be provided on update')
    elsif personable.id != Current.person.personable_id && Current.person.personable_id.present?
      errors.add(:personable_id, 'must match the current person')
    end
  end
end

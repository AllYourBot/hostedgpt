# == Schema Information
#
# Table name: people
#
#  id              :bigint           not null, primary key
#  email           :string
#  personable_type :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  personable_id   :bigint
#
# Indexes
#
#  index_people_on_personable  (personable_type,personable_id)
#

class Person < ApplicationRecord
  encrypts :email, deterministic: true

  delegated_type :personable, types: %w[User Tombstone]
  accepts_nested_attributes_for :personable

  validate :personable_id_unchanged, on: :update
  validates_associated :personable
  validates :email, presence: true, uniqueness: true
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

class Person < ApplicationRecord
  delegated_type :personable, types: %w[ User Tombstone ], dependent: :destroy
  has_many :clients, dependent: :destroy

  accepts_nested_attributes_for :personable

  validate :personable_id_unchanged, on: :update
  validates_associated :personable
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :proper_personable_id, on: :update

  encrypts :email, deterministic: true

  scope :ordered, -> { order(:created_at) }

  normalizes :email, with: -> email { email.downcase.strip }

  private

  def personable_id_unchanged
    if personable_id_changed? && persisted?
      errors.add(:personable_id, I18n.t('errors.messages.cannot_be_changed_after_creation'))
    end
  end

  def proper_personable_id
    if personable_id.present? && personable.id.blank?
      errors.add(:personable_id, I18n.t('errors.messages.must_be_provided_on_update'))
    end
  end
end

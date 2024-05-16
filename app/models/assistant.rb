class Assistant < ApplicationRecord
  belongs_to :user

  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
  has_many :messages # TODO: What should happen if an assistant is deleted?

  belongs_to :language_model

  validates :tools, presence: true, allow_blank: true
  validates :name, presence: true

  MAX_LIST_DISPLAY = 5

  scope :ordered, -> { order(:id) }

  scope :not_deleted, -> { where(deleted_at: nil) }

  def initials
    return nil if name.blank?

    parts = name.split(/[\- ]/)

    parts[0][0].capitalize +
      parts[1]&.try(:[], 0)&.capitalize.to_s
  end

  def destroy
    raise "Can't delete user's last assistant" if user.assistants.count < 2
    update!(deleted_at: Time.now)
  end

  def deleted?
    deleted_at.present?
  end

  def to_s
    name
  end
end

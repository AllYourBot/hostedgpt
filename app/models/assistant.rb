class Assistant < ApplicationRecord
  MAX_LIST_DISPLAY = 5

  belongs_to :user

  has_many :conversations
  has_many :documents
  has_many :runs
  has_many :steps
  has_many :messages

  delegate :supports_images?, to: :language_model

  belongs_to :language_model

  validates :tools, presence: true, allow_blank: true
  validates :name, presence: true

  scope :ordered, -> { order(:id) }

  def initials
    return nil if name.blank?

    parts = name.split(/[\- ]/)

    parts[0][0].capitalize +
      parts[1]&.try(:[], 0)&.capitalize.to_s
  end

  def destroy
    if user.destroy_in_progress?
      super
    else
      raise "Can't delete user's last assistant" if user.assistants.count <= 1
      update!(deleted_at: Time.now)
    end
  end

  def to_s
    name
  end
end

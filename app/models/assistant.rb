class Assistant < ApplicationRecord
  MAX_LIST_DISPLAY = 5

  belongs_to :user

  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
  has_many :messages, dependent: :destroy

  delegate :supports_images?, to: :language_model
  delegate :api_service, to: :language_model

  belongs_to :language_model

  validates :tools, presence: true, allow_blank: true
  validates :name, presence: true

  scope :ordered, -> { order(:id) }

  def destroy_in_database!
    @destroy_in_database = true
    begin
      destroy!
    ensure
      @destroy_in_database = false
    end
  end

  def destroy
    if @destroy_in_database || user.destroy_in_progress?
      super
    else
      update!(deleted_at: Time.now) # We leave all the conversations, messages etc still intact.
    end
  end

  def initials
    return nil if name.blank?

    parts = name.split(/[\- ]/)

    parts[0][0].capitalize +
      parts[1]&.try(:[], 0)&.capitalize.to_s
  end

  def to_s
    name
  end
end

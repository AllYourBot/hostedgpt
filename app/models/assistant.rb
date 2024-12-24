class Assistant < ApplicationRecord
  include Export
  include Slug

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

  delegate :api_name, to: :language_model, prefix: true, allow_nil: true

  def initials
    return nil if name.blank?

    parts = name.split(/[\- ]/)

    parts[0][0].capitalize +
      parts[1]&.try(:[], 0)&.capitalize.to_s
  end

  def to_s
    name
  end

  def language_model_api_name=(api_name)
    self.language_model = LanguageModel.for_user(user).find_by(api_name:)
  end
end

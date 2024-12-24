class Assistant < ApplicationRecord
  include Export

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

  before_validation :set_default_slug

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

  private

  # Set the slug to the name, downcased, with non-word characters replaced with "-"
  # and trailing "-" removed.
  # If the slug is not unique for the user, append "-2", "-3", etc.
  def set_default_slug
    return if slug.present?
    return if name.blank?

    base_slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-$/, "")

    existing_base_slugs = user.assistants.where("slug LIKE ?", "#{base_slug}%").pluck(:slug)
    largest_slug_number = existing_base_slugs.map { |slug| slug.split("--").last.to_i }.max
    self.slug = if largest_slug_number.present?
      "#{base_slug}--#{largest_slug_number + 1}"
    elsif existing_base_slugs.any?
      "#{base_slug}--1"
    else
      base_slug
    end
  end
end

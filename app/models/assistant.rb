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
  delegate :supports_pdf?, to: :language_model
  delegate :api_service, to: :language_model
  delegate :logo_filename, to: :language_model, allow_nil: true

  belongs_to :language_model

  validates :tools, presence: true, allow_blank: true
  validates :name, presence: true

  scope :ordered, -> { order(:position, id: :desc) }

  before_create :position_at_top

  delegate :api_name, to: :language_model, prefix: true, allow_nil: true

  # Renumbers this collection to match the order of ids, which is how the sidebar hands back a list
  # the user has dragged into shape. Ids the collection does not contain are simply ignored, so a
  # user-scoped relation cannot be talked into reordering someone else's assistants.
  def self.reposition(ids)
    ids = ids.map(&:to_i)

    transaction do
      where(id: ids).each { |assistant| assistant.update_column(:position, ids.index(assistant.id)) }
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

  def language_model_api_name=(api_name)
    self.language_model = LanguageModel.for_user(user).find_by(api_name:)
  end

  private

  # A new assistant belongs at the top of the list, which is where it landed back when the list was
  # ordered newest-first.
  def position_at_top
    self.position ||= (user.assistants_including_deleted.minimum(:position) || 0) - 1
  end
end

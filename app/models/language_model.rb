# We don"t care about large or not
class LanguageModel < ApplicationRecord
  BEST_GPT = "gpt-best"
  BEST_CLAUDE = "claude-best"

  BEST_MODELS = {
    BEST_GPT => "gpt-4o-2024-05-13",
    BEST_CLAUDE => "claude-3-5-sonnet-20240620"
  }

  belongs_to :user
  belongs_to :api_service

  has_many :assistants, -> { not_deleted }
  has_many :assistants_including_deleted, class_name: "Assistant", dependent: :destroy

  before_validation :populate_position, unless: :position

  validates :api_name, :name, :position, presence: true

  before_save :soft_delete_assistants, if: -> { has_attribute?(:deleted_at) && deleted_at && deleted_at_changed? && deleted_at_was.nil? }

  scope :ordered, -> { order(:position) }
  scope :for_user, ->(user) { where(user_id: user.id).not_deleted }

  delegate :ai_backend, to: :api_service

  def provider_name
    BEST_MODELS[api_name] || api_name
  end

  def created_by_current_user?
    user == Current.user
  end

  def self.create_without_validation!(attributes)
    record = LanguageModel.new(attributes)
    if !record.save(validate: false)
      raise "Could not create LanguageModel record for #{attributes.inspect}"
    end
    record
  end


  private

  def populate_position
    self.position = (user&.language_models&.maximum(:position) || 0) + 1
  end

  def soft_delete_assistants
    assistants.update_all(deleted_at: Time.current)
  end
end

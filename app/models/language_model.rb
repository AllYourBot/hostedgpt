# We don"t care about large or not
class LanguageModel < ApplicationRecord
  BEST_GPT = "gpt-best"
  BEST_CLAUDE = "claude-best"

  BEST_MODELS = {
    BEST_GPT => "gpt-4o-2024-05-13",
    BEST_CLAUDE => "claude-3-opus-20240229"
  }

  belongs_to :user
  belongs_to :api_service

  has_many :assistants, -> { not_deleted }
  has_many :assistants_including_deleted, class_name: "Assistant", dependent: :destroy

  validates :api_name, :description, presence: true

  before_create :populate_position

  scope :ordered, -> { order(:position) }
  scope :for_user, ->  (user) { where(user_id: user.id).not_deleted }

  delegate :ai_backend, to: :api_service

  def delete!
    update!(deleted_at: Time.now)
    assistants.each { |assistant| assistant.deleted! }
  end

  def provider_name
    BEST_MODELS[api_name] || api_name
  end

  def created_by_current_user?
    user == Current.user
  end

  private

  def populate_position
    return unless position.blank?
    self.position = (LanguageModel.maximum(:position) || 0) + 1
  end
end

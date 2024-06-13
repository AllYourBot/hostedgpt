# We don"t care about large or not
class LanguageModel < ApplicationRecord
  BEST_MODELS = {
    "gpt-best" => "gpt-4o-2024-05-13",
    "claude-best" => "claude-3-opus-20240229"
  }

  belongs_to :user, optional: true
  belongs_to :api_service, optional: true

  has_many :assistants, -> { not_deleted }

  validates :name, :description, presence: true

  before_create :populate_position

  scope :ordered, -> { order(:position) }
  scope :for_user, ->  (user) { where(user_id: [user.id, nil]).not_deleted }
  scope :system_wide, ->  { where(user_id: nil) }

  def ai_backend
    if api_service.present?
      api_service.ai_backend
    elsif name.starts_with?('gpt-')
      AIBackend::OpenAI
    else
      AIBackend::Anthropic
    end
  end

  def readonly?
    user_id.blank?
  end

  def destroy
    raise ActiveRecord::ReadOnlyError 'System model cannot be deleted' if user.blank?
    if user.destroy_in_progress?
      super
    else
      update!(deleted_at: Time.now)
      assistants.each { |assistant| assistant.destroy! }
    end
  end

  def provider_name
    BEST_MODELS[name] || name
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

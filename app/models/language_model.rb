# We don't care about large or not
class LanguageModel < ApplicationRecord
  encrypts :access_token

  belongs_to :user, optional: true

  validates :api_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]),  if: -> { api_url.present? }
  validates :name, :description, presence: true

  BEST_MODELS = {
    'gpt-best' => 'gpt-4o-2024-05-13',
    'claude-best' => 'claude-3-opus-20240229'
  }

  def read_only?
    user_id.blank?
  end

  def destroy
    raise ActiveRecord::ReadOnlyError 'System model cannot be deleted' if user.blank?
    if user.destroy_in_progress?
      super
    else
      update!(deleted_at: Time.now)
    end
  end

  scope :ordered, -> { order(:position) }

  before_create :populate_position

  has_many :assistants

  def provider_name
    BEST_MODELS[name] || name
  end

  def ai_backend
    if name.starts_with?('gpt-')
      AIBackend::OpenAI
    else
      AIBackend::Anthropic
    end
  end

  def created_by_current_user?
    user == Current.user
  end

  def populate_position
    return unless position.blank?
    self.position = (LanguageModel.maximum(:position) || 0) + 1
  end

end

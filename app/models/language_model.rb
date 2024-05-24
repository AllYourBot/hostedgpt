# We don't care about large or not
class LanguageModel < ApplicationRecord
  BEST_MODELS = {
    'gpt-best' => 'gpt-4o-2024-05-13',
    'claude-best' => 'claude-3-opus-20240229'
  }

  scope :ordered, -> { order(:position) }

  has_many :assistants

  def readonly?
    !new_record?
  end

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
end

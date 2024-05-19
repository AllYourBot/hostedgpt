# We don't care about large or not
class LanguageModel < ApplicationRecord
  scope :ordered, -> { order(:position) }

  has_many :assistants

  def readonly?
    !new_record?
  end

  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end

  PROVIDER_ID_MAP = {'gpt-best': 'gpt-4-turbo',
     'claude-best': 'claude-3-opus-20240229'}

  def provider_id
    PROVIDER_ID_MAP[self.name.to_sym] || self.name unless self.name =~ /^best/
  end

  def ai_backend
    if name.starts_with?('gpt-')
      AIBackends::OpenAI
    else
      AIBackends::Anthropic
    end
  end
end

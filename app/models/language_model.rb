# We don't care about large or not
class LanguageModel < ApplicationRecord
  def readonly?() = !new_record?
  def before_destroy() = raise ActiveRecord::ReadOnlyRecord

  PROVIDER_ID_MAP = {'gpt-best': 'gpt-4-turbo',
     'claude-best': 'claude-3-opus-20240229'}             

  GPT_BEST_ID        = 1
  CLAUDE_BEST_ID     = 2
  GPT_3_5_ID         = 12
  CLAUDE_3_SONNET_ID = 18

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

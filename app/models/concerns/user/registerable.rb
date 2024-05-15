module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistants
  end

  private

  def create_initial_assistants
    assistants.create! name: "GPT (best)", language_model_id: LanguageModel::GPT_BEST_ID,  images: true
    assistants.create! name: "GPT-3.5", language_model_id: LanguageModel::GPT_3_5_ID, images: false
    assistants.create! name: "Claude (best)", language_model_id: LanguageModel::CLAUDE_BEST_ID, images: true
    assistants.create! name: "Claude 3 Sonnet", language_model_id: LanguageModel::CLAUDE_3_SONNET_ID, images: true
  end
end

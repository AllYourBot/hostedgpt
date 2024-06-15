module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistants
  end

  private

  def create_initial_assistants
    assistants.create! name: "GPT-4o", language_model: LanguageModel.find_by(api_name: "gpt-best")
    assistants.create! name: "GPT-3.5", language_model: LanguageModel.find_by(api_name: "gpt-3.5-turbo")
    assistants.create! name: "Claude 3 Opus", language_model: LanguageModel.find_by(api_name: "claude-best")
    assistants.create! name: "Claude 3 Sonnet", language_model: LanguageModel.find_by(api_name: "claude-3-sonnet-20240229")
  end
end

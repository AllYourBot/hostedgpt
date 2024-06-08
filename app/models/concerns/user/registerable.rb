module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistants
  end

  private

  def create_initial_assistants
    language_model = LanguageModel.find_by(name: 'gpt-4o') || LanguageModel.create!(position: 1, supports_images: true, description: "gpt-4o")
    assistants.create! name: "GPT-4o", language_model: language_model
    language_model = LanguageModel.find_by(name: 'gpt-3.5-turbo') || LanguageModel.create!(position: 2, supports_images: false, description: "gpt-3.5-turbo")
    assistants.create! name: "GPT-3.5", language_model: language_model
    language_model = LanguageModel.find_by(name: 'claude-3-opus-20240229') || LanguageModel.create!(position: 3, supports_images: true, description: "claude-3-opus-20240229")
    assistants.create! name: "Claude 3 Opus", language_model: language_model
    language_model = LanguageModel.find_by(name: 'claude-3-sonnet-20240229') || LanguageModel.create!(position: 4, supports_images: true, description: "claude-3-sonnet-20240229")
    assistants.create! name: "Claude 3 Sonnet", language_model: language_model
  end
end

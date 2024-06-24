module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistants_etc
  end

  private

  def create_initial_assistants_etc
    open_ai_api_service = api_services.create!(url: APIService::URL_OPEN_AI, driver: :openai, name: "OpenAI")

    [
      [LanguageModel::BEST_GPT, "Best OpenAI Model", true, "GPT-4o"],
      ["gpt-3.5-turbo", "GPT-3.5 Turbo (latest)", false, "GPT-3.5"]
    ].collect do |api_name, name, supports_images, assistant_name|
      language_model = language_models.create!(api_name: api_name, api_service: open_ai_api_service, name: name, supports_images: supports_images)
      assistants.create! name: assistant_name, language_model: language_model
    end

    anthropic_api_service = api_services.create!(url: APIService::URL_ANTHROPIC, driver: :anthropic, name: "Anthropic")

    [
      [LanguageModel::BEST_CLAUDE, "Best Anthropic Model", true, "Claude 3.5 Sonnet"],
      ["claude-3-opus-20240229", "Claude 3 Opus (2024-04-29)", true, "Claude 3 Opus"]
    ].collect do |api_name, name, supports_images, assistant_name|
      language_model = language_models.create!(api_name: api_name, api_service: anthropic_api_service, name: name, supports_images: supports_images)
      assistants.create! name: assistant_name, language_model: language_model
    end
  end
end

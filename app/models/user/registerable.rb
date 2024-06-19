module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistants_etc
  end

  private

  # Alo creates user's APIService  and LanguageModel records
  def create_initial_assistants_etc
    open_ai_api_service = api_services.create!(url: APIService::URL_OPEN_AI, driver: APIService::DRIVER_OPEN_AI, name: "OpenAI")

    [[LanguageModel::BEST_GPT, "Best OpenAI Model", true, "GPT Best"],
     ["gpt-3.5-turbo", "GPT-3.5 Turbo (latest)", false, "GPT-3.5"]].collect do |api_name, description, supports_images, assistant_name|
     language_model = language_models.create!(api_name: api_name, api_service: open_ai_api_service, description: description, supports_images: supports_images)
     assistants.create! name: assistant_name, language_model: language_model 
   end

   anthropic_api_service = api_services.create!(url: APIService::URL_ANTHROPIC, driver: APIService::DRIVER_ANTHROPIC, name: "Anthropic")

    [[LanguageModel::BEST_CLAUDE, "Best Anthropic Model", true, "Claude Best"],
     ["claude-3-sonnet-20240229", "Claude 3 Sonnet (2024-02-29)", true, "Claude 3 Sonnet"]].collect do |api_name, description, supports_images, assistant_name|
      language_model = language_models.create!(api_name: api_name, api_service: anthropic_api_service, description: description, supports_images: supports_images)
      assistants.create! name: assistant_name, language_model: language_model
    end
  end
end

module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistants_etc
  end

  private

  def create_initial_assistants_etc
    open_ai_api_service = api_services.create!(url: APIService::URL_OPEN_AI, driver: :openai, name: "OpenAI")
    anthropic_api_service = api_services.create!(url: APIService::URL_ANTHROPIC, driver: :anthropic, name: "Anthropic")
    groq_api_service = api_services.create!(url: APIService::URL_GROQ, driver: :openai, name: "Groq")

    LanguageModel.import_from_file(users: [self])

    [
      ["GPT-4o", open_ai_api_service],
      ["Claude 3.5 Sonnet", anthropic_api_service],
      ["Meta Llama 3 70b", groq_api_service],
    ].map do |name, api_service|
      language_model = language_models.best_for_api_service(api_service).first
      description = "Model #{language_model.api_name} on #{api_service.name}"
      assistants.create! name:, description:, language_model:
    end
  end
end

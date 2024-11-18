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

    assistants.create! name: "GPT-4o", language_model: language_models.best_for_api_service(open_ai_api_service).first
    assistants.create! name: "Claude 3.5 Sonnet", language_model: language_models.best_for_api_service(anthropic_api_service).first
    assistants.create! name: "Meta Llama 3 70b", language_model: language_models.best_for_api_service(groq_api_service).first
  end
end

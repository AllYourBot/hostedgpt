module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistants_etc
  end

  private

  def create_initial_assistants_etc
    api_services.create!(url: APIService::URL_OPEN_AI, driver: :openai, name: "OpenAI")
    api_services.create!(url: APIService::URL_ANTHROPIC, driver: :anthropic, name: "Anthropic")
    api_services.create!(url: APIService::URL_GROQ, driver: :openai, name: "Groq")
    api_services.create!(url: APIService::URL_GEMINI, driver: :gemini, name: "Google Gemini")

    LanguageModel.import_from_file(users: [self])
    Assistant.import_from_file(users: [self])
  end
end

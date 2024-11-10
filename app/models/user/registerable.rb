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

    best_models = %w[gpt-4o claude-3-5-sonnet-20240620 llama3-70b-8192]
    [
      ["gpt-4o", "GPT-4o (latest)", true, open_ai_api_service, 250, 1000],
      ["gpt-4o-2024-08-06", "GPT-4o Omni Multimodal (2024-08-06)", true, open_ai_api_service, 250, 1000],
      ["gpt-4o-2024-05-13", "GPT-4o Omni Multimodal (2024-05-13)", true, open_ai_api_service, 500, 1500],

      ["gpt-4-turbo", "GPT-4 Turbo with Vision (latest)", true, open_ai_api_service, 1000, 3000],
      ["gpt-4-turbo-2024-04-09", "GPT-4 Turbo with Vision (2024-04-09)", true, open_ai_api_service, 1000, 3000],
      ["gpt-4-turbo-preview", "GPT-4 Turbo Preview", false, open_ai_api_service, 1000, 3000],
      ["gpt-4-0125-preview", "GPT-4 Turbo Preview (2024-01-25)", false, open_ai_api_service, 1000, 3000],
      ["gpt-4-1106-preview", "GPT-4 Turbo Preview (2023-11-06)", false, open_ai_api_service, 1000, 3000],
      ["gpt-4-vision-preview", "GPT-4 Turbo with Vision Preview (2023-11-06)", true, open_ai_api_service, 1000, 3000],
      ["gpt-4-1106-vision-preview", "GPT-4 Turbo with Vision Preview (2023-11-06)", true, open_ai_api_service, 1000, 3000],

      ["gpt-4", "GPT-4 (latest)", false, open_ai_api_service, 3000, 6000],
      ["gpt-4-0613", "GPT-4 Snapshot improved function calling (2023-06-13)", false, open_ai_api_service, 1000, 3000],

      ["gpt-3.5-turbo", "GPT-3.5 Turbo (latest)", false, open_ai_api_service, 300, 600],
      ["gpt-3.5-turbo-0125", "GPT-3.5 Turbo (2022-01-25)", false, open_ai_api_service, 50, 150],
      ["gpt-3.5-turbo-1106", "GPT-3.5 Turbo (2022-11-06)", false, open_ai_api_service, 100, 200],

      ["claude-3-5-sonnet-20240620", "Claude 3.5 Sonnet (2024-06-20)", true, anthropic_api_service, 300, 1500],
      ["claude-3-opus-20240229", "Claude 3 Opus (2024-02-29)", true, anthropic_api_service, 1500, 7500],
      ["claude-3-sonnet-20240229", "Claude 3 Sonnet (2024-02-29)", true, anthropic_api_service, 300, 1500],
      ["claude-3-haiku-20240307", "Claude 3 Haiku (2024-03-07)", true, anthropic_api_service, 25, 125],
      ["claude-2.1", "Claude 2.1", false, anthropic_api_service, 800, 2400],
      ["claude-2.0", "Claude 2.0", false, anthropic_api_service, 800, 2400],
      ["claude-instant-1.2", "Claude Instant 1.2", false, anthropic_api_service, 80, 240],

      ["llama3-70b-8192", "Meta Llama 3 70b", false, groq_api_service, 59, 79],
      ["llama3-8b-8192", "Meta Llama 3 8b", false, groq_api_service, 5, 8],
      ["mixtral-8x7b-32768", "Mistral 8 7b", false, groq_api_service, 24, 24],
      ["gemma-7b-it", "Google Gemma 7b", false, groq_api_service, 7, 7],
    ].each do |api_name, name, supports_images, api_service, input_token_cost_per_million, output_token_cost_per_million|
      million = BigDecimal(1_000_000)
      input_token_cost_cents = input_token_cost_per_million/million
      output_token_cost_cents = output_token_cost_per_million/million

      language_models.create!(
        api_name:,
        api_service:,
        name:,
        best: best_models.include?(api_name),
        supports_tools: true,
        supports_images:,
        input_token_cost_cents:,
        output_token_cost_cents:,
      )
    end

    # Only these don't support tools:
    [
      ["gpt-3.5-turbo-instruct", "GPT-3.5 Turbo Instruct", false, open_ai_api_service, 150, 200],
      ["gpt-3.5-turbo-16k-0613", "GPT-3.5 Turbo (2022-06-13)", false, open_ai_api_service, 300, 400],
    ].each do |api_name, name, supports_images, api_service, input_token_cost_per_million, output_token_cost_per_million|
      million = BigDecimal(1_000_000)
      input_token_cost_cents = input_token_cost_per_million/million
      output_token_cost_cents = output_token_cost_per_million/million

      language_models.create!(api_name:, api_service:, name:, supports_tools: false, supports_images:, input_token_cost_cents:, output_token_cost_cents:)
    end

    assistants.create! name: "GPT-4o", language_model: language_models.best_for_api_service(open_ai_api_service).first
    assistants.create! name: "Claude 3.5 Sonnet", language_model: language_models.best_for_api_service(anthropic_api_service).first
    assistants.create! name: "Meta Llama 3 70b", language_model: language_models.best_for_api_service(groq_api_service).first
  end
end

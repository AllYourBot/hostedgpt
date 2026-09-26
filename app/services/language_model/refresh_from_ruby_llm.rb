class LanguageModel::RefreshFromRubyLLM
  Result = Struct.new(:added_count, :missing_provider_identities, keyword_init: true)

  CANONICAL_PROVIDER_URLS = {
    openai: APIService::URL_OPEN_AI,
    anthropic: APIService::URL_ANTHROPIC,
    groq: APIService::URL_GROQ,
    openrouter: APIService::URL_OPENROUTER,
    gemini: APIService::URL_GEMINI,
  }.freeze

  def initialize(registry: RubyLLM.models)
    @registry = registry
  end

  def call
    @registry.refresh!
    models_by_provider = @registry.chat_models.all.group_by(&:provider)
    api_services = APIService.not_deleted.includes(:user).select do |api_service|
      canonical_chat_service?(api_service)
    end

    added_count = api_services.sum do |api_service|
      refresh_api_service(api_service, models_by_provider)
    end

    configured_providers = api_services.filter_map { |api_service| api_service.provider_identity&.to_s }.uniq
    missing_provider_identities = APIService.chat_provider_identities.filter_map do |provider|
      provider_name = provider.to_s
      provider_name if configured_providers.include?(provider_name) && models_by_provider[provider_name].blank?
    end

    Result.new(added_count:, missing_provider_identities:)
  end

  private

  def canonical_chat_service?(api_service)
    CANONICAL_PROVIDER_URLS[api_service.provider_identity] == api_service.url
  end

  def refresh_api_service(api_service, models_by_provider)
    provider = api_service.provider_identity&.to_s
    models = models_by_provider[provider]
    return 0 if models.blank?

    existing_api_names = api_service.user.language_models_including_deleted
      .where(api_service: api_service)
      .pluck(:api_name)

    models.sum do |model|
      next 0 if existing_api_names.include?(model.id)

      api_service.user.language_models.create!(
        api_service: api_service,
        api_name: model.id,
        name: model.name,
        supports_images: model.modalities.input.include?("image"),
        supports_pdf: model.modalities.input.include?("pdf"),
        supports_system_message: true,
        supports_tools: model.supports_functions?
      )

      existing_api_names << model.id
      1
    end
  end
end

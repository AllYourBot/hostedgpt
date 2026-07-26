module LanguageModel::Export
  extend ActiveSupport::Concern

  DEFAULT_EXPORT_ONLY = %i[
    api_name
    name
    api_service_name
    supports_images
    supports_tools
    supports_system_message
  ]

  DEFAULT_MODEL_FILE = "models.yml"

  def attributes
    super.merge("api_service_name" => api_service_name)
  end

  # Unsure why this needs to re-defined, but the original ActiveModel::Serialization
  # implementation is ignoring the #attributes method above.
  def attribute_names_for_serialization
    attributes.keys
  end

  class_methods do
    def export_to_file(path: Rails.root.join(DEFAULT_MODEL_FILE), models:, only: DEFAULT_EXPORT_ONLY)
      path = path.to_s
      storage = {
        "models" => models.as_json(only:).map(&:compact)
      }
      if path.ends_with?(".json")
        File.write(path, storage.to_json)
      else
        File.write(path, storage.to_yaml)
      end
    end

    def import_from_file(path: Rails.root.join(DEFAULT_MODEL_FILE), users: User.all)
      users = Array.wrap(users)
      storage = YAML.load_file(path)
      models = storage["models"]
      models.each do |model|
        model = model.with_indifferent_access
        users.each do |user|
          lm = user.language_models.find_or_initialize_by(api_name: model[:api_name])
          lm.api_service = user.api_services.find_by(name: model[:api_service_name]) if model[:api_service_name]
          lm.assign_attributes(model.except(:api_service_name))
          lm.save!
        rescue ActiveRecord::RecordInvalid => e
          warn "Failed to import '#{model[:api_name]}': #{e.message} for #{model.inspect}"
        end
      end
    end

    PROVIDER_TO_SERVICE_NAME = {
      "openai" => "OpenAI",
      "anthropic" => "Anthropic",
      "gemini" => "Google Gemini",
    }.freeze

    def import_rubyllm_registry(users: User.all)
      count = 0

      RubyLLM.models.chat_models.each do |model|
        service_name = PROVIDER_TO_SERVICE_NAME[model.provider]
        next unless service_name

        Array.wrap(users).each do |user|
          count += 1 if create_model_from_registry(model, user, service_name)
        end
      end

      count
    end

    def create_model_from_registry(model, user, service_name)
      api_service = user.api_services.find_by(name: service_name)
      return unless api_service
      return if user.language_models.exists?(api_name: model.id)

      user.language_models.create!(
        api_name: model.id,
        name: model.name || model.id,
        api_service: api_service,
        supports_images: model.capabilities&.include?("vision") || model.modalities.input.include?("image"),
        supports_tools: model.capabilities&.include?("function_calling") || false,
        supports_system_message: true,
        supports_pdf: model.modalities.input.include?("pdf") || false,
      )
      true
    rescue ActiveRecord::RecordInvalid => e
      warn "Failed to import '#{model.id}': #{e.message}"
    end
  end
end

module LanguageModel::Export
  extend ActiveSupport::Concern

  def as_json(options = {})
    options = options.with_indifferent_access
    attrs = super(options)
    attrs["api_service_name"] = api_service_name if options[:only].include?(:api_service_name)
    attrs
  end

  class_methods do
    def export_to_file(path:, models:, only: %i[api_name name api_service_name supports_images supports_tools input_token_cost_cents output_token_cost_cents])
      path = path.to_s
      storage = {
        "models" => models.as_json(only:)
      }
      if path.ends_with?(".json")
        File.write(path, storage.to_json)
      else
        File.write(path, storage.to_yaml)
      end
    end

    def import_from_file(path:, users: User.all)
      users = Array.wrap(users)
      storage = YAML.load_file(path)
      models = storage["models"]
      models.each do |model|
        model = model.with_indifferent_access
        users.each do |user|
          lm = user.language_models.find_or_initialize_by(api_name: model[:api_name])
          lm.api_service = user.api_services.find_by(name: model[:api_service_name]) if model[:api_service_name]
          lm.attributes = model.except(:api_service_name)
          lm.save!
        rescue ActiveRecord::RecordInvalid => e
          warn "Failed to import '#{model[:api_name]}': #{e.message} for #{model.inspect}"
        end
      end
    end
  end
end

module Assistant::Export
  extend ActiveSupport::Concern

  DEFAULT_EXPORT_ONLY = %i[
    name
    slug
    description
    instructions
    language_model_api_name
  ]

  DEFAULT_ASSISTANT_FILE = "assistants.yml"

  def attributes
    super.merge("language_model_api_name" => language_model_api_name)
  end

  # Unsure why this needs to re-defined, but the original ActiveModel::Serialization
  # implementation is ignoring the #attributes method above.
  def attribute_names_for_serialization
    attributes.keys
  end

  class_methods do
    def export_to_file(path: Rails.root.join(DEFAULT_ASSISTANT_FILE), assistants:, only: DEFAULT_EXPORT_ONLY)
      path = path.to_s
      storage = {
        "assistants" => assistants.as_json(only:).map(&:compact)
      }
      if path.ends_with?(".json")
        File.write(path, storage.to_json)
      else
        File.write(path, storage.to_yaml)
      end
    end

    def import_from_file(path: Rails.root.join(DEFAULT_ASSISTANT_FILE), users: User.all)
      users = Array.wrap(users)

      storage = YAML.load_file(path)
      assistants = storage["assistants"]
      assistants.each do |assistant|
        assistant = assistant.with_indifferent_access
        users.each do |user|
          asst = user.assistants.find_or_create_by(slug: assistant["slug"])
          asst.assign_attributes(assistant.except("slug")) if asst.deleted_at.nil?
          asst.save!
        end
      end
    end
  end
end

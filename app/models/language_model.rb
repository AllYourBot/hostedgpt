# We don"t care about large or not
class LanguageModel < ApplicationRecord
  BEST_GPT = "gpt-best"
  BEST_CLAUDE = "claude-best"
  BEST_GROQ = "groq-best"

  # TODO: infer these from models.yaml
  BEST_MODELS = {
    BEST_GPT => "gpt-4o-2024-08-06",
    BEST_CLAUDE => "claude-3-5-sonnet-20240620",
    BEST_GROQ => "llama3-70b-8192",
  }

  # TODO: what are these for?
  BEST_MODEL_INPUT_PRICES = {
    BEST_GPT => 250,
    BEST_CLAUDE => 300,
    BEST_GROQ => 59,
  }

  BEST_MODEL_OUTPUT_PRICES = {
    BEST_GPT => 1000,
    BEST_CLAUDE => 1500,
    BEST_GROQ => 79,
  }

  belongs_to :user
  belongs_to :api_service

  has_many :assistants, -> { not_deleted }
  has_many :assistants_including_deleted, class_name: "Assistant", dependent: :destroy

  before_validation :populate_position, unless: :position

  validates :api_name, :name, :position, presence: true

  before_save :soft_delete_assistants, if: -> { has_attribute?(:deleted_at) && deleted_at && deleted_at_changed? && deleted_at_was.nil? }

  scope :ordered, -> { order(:position) }
  scope :for_user, ->(user) { where(user_id: user.id).not_deleted }

  delegate :ai_backend, to: :api_service

  def provider_name
    BEST_MODELS[api_name] || api_name
  end

  def created_by_current_user?
    user == Current.user
  end

  def api_service_name
    api_service.name
  end

  def as_json(options = {})
    options = options.with_indifferent_access
    attrs = super(options)
    attrs["api_service_name"] = api_service_name if options[:only].include?(:api_service_name)
    attrs
  end

  def supports_tools?
    attributes["supports_tools"] &&
      api_service.name != "Groq" # TODO: Remove this short circuit once I can debug tool use with Groq
  end

  def self.export_to_file(path:, models:, only: %i[api_name name api_service_name supports_images supports_tools input_token_cost_cents output_token_cost_cents])
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

  def self.import_from_file(path:, users: User.all)
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

  private

  def populate_position
    self.position = (user&.language_models&.maximum(:position) || 0) + 1
  end

  def soft_delete_assistants
    assistants.update_all(deleted_at: Time.current)
  end
end

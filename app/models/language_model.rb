# We don"t care about large or not
class LanguageModel < ApplicationRecord
  include Export

  belongs_to :user
  belongs_to :api_service

  has_many :assistants, -> { not_deleted }
  has_many :assistants_including_deleted, class_name: "Assistant", dependent: :destroy

  before_validation :populate_position, unless: :position

  validates :api_name, :name, :position, presence: true

  before_save :soft_delete_assistants, if: -> { has_attribute?(:deleted_at) && deleted_at && deleted_at_changed? && deleted_at_was.nil? }
  after_save :update_best_language_model_for_api_service

  scope :ordered, -> { order(Arel.sql("CASE WHEN best THEN 0 ELSE position END")).order(:position) }
  scope :for_user, ->(user) { where(user_id: user.id).not_deleted }
  scope :best_for_api_service, ->(api_service) { where(best: true, api_service: api_service) }

  delegate :ai_backend, to: :api_service
  delegate :name, to: :api_service, prefix: true, allow_nil: true

  def created_by_current_user?
    user == Current.user
  end

  def supports_tools?
    attributes["supports_tools"] &&
      api_service.name != "Groq" # TODO: Remove this short circuit once I can debug tool use with Groq
  end

  def test(api_name = nil)
    ai_backend.test_language_model(self, api_name)
  end

  # Records can be labelled "best" for that API Service. When an api_name ends in "-best" we use the one
  # labelled best for the service. Note the api_service's are scoped to the user.
  def effective_api_name
    if api_name =~ /-best\Z/
      begin
        Current.user.language_models.best_for_api_service(api_service).first.api_name
      rescue => e
        Rails.logger.info "Could not resolve best model for #{api_name} from API service #{api_service.name} : #{e}"
        raise "Could not resolve best model for #{api_name} from API service #{api_service.name}"
      end
    else
      api_name
    end
  end

  private

  def populate_position
    self.position = (user&.language_models&.maximum(:position) || 0) + 1
  end

  def soft_delete_assistants
    assistants.update_all(deleted_at: Time.current)
  end

  # Only one best language model per API service
  def update_best_language_model_for_api_service
    if best?
      api_service.language_models.update_all(best: false)
      update_column(:best, true)
    end
  end
end

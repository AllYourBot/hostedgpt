class User < ApplicationRecord
  include Personable, Registerable
  encrypts :openai_key, :anthropic_key

  has_secure_password validations: false
  has_person_name

  validates :first_name, presence: true
  validates :last_name, presence: true, on: :create

  has_many :assistants, -> { not_deleted }
  has_many :assistants_including_deleted, class_name: "Assistant", inverse_of: :user, dependent: :destroy
  has_many :language_models, -> { not_deleted }
  has_many :language_models_including_deleted, class_name: "LanguageModel", dependent: :destroy
  has_many :api_services, -> { not_deleted }
  has_many :api_services_including_deleted, class_name: "APIService", dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :credentials, dependent: :destroy

  has_one :password_credential, -> { type_is("PasswordCredential") }, class_name: "Credential", inverse_of: :user
  has_one :google_credential, -> { type_is("GoogleCredential") }, class_name: "Credential", inverse_of: :user
  has_one :gmail_credential, -> { type_is("GmailCredential") }, class_name: "Credential", inverse_of: :user
  has_one :http_header_credential, -> { type_is("HttpHeaderCredential") }, class_name: "Credential", inverse_of: :user

  belongs_to :last_cancelled_message, class_name: "Message", optional: true

  accepts_nested_attributes_for :credentials
  serialize :preferences, coder: JsonSerializer

  def preferences
    attributes["preferences"].with_defaults(dark_mode: "system")
  end

  # Which ones can they choose for their api services
  def usable_language_models
    LanguageModel.for_user(self).not_deleted
  end

  def destroy_in_progress?
    @destroy_in_progress
  end

  def destroy
    @destroy_in_progress = true
    begin
      super
    ensure
      @destroy_in_progress = false
    end
  end

  def openai_key
    self.attributes["openai_key"].presence || (Feature.default_llm_keys? ? Setting.default_openai_key : nil)
  end

  def anthropic_key
    self.attributes["anthropic_key"].presence || (Feature.default_llm_keys? ? Setting.default_anthropic_key : nil)
  end
end

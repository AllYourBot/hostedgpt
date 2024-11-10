class User < ApplicationRecord
  include Personable, Registerable

  has_secure_password validations: false
  has_person_name

  has_many :assistants, -> { not_deleted }
  has_many :assistants_including_deleted, class_name: "Assistant", inverse_of: :user, dependent: :destroy
  has_many :language_models, -> { not_deleted }
  has_many :language_models_including_deleted, class_name: "LanguageModel", dependent: :destroy
  has_many :api_services, -> { not_deleted }
  has_many :api_services_including_deleted, class_name: "APIService", dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :credentials, dependent: :destroy
  has_many :memories, dependent: :destroy

  has_one :password_credential, -> { type_is("PasswordCredential") }, class_name: "Credential", inverse_of: :user
  has_one :google_credential, -> { type_is("GoogleCredential") }, class_name: "Credential", inverse_of: :user
  has_one :gmail_credential, -> { type_is("GmailCredential") }, class_name: "Credential", inverse_of: :user
  has_one :google_tasks_credential, -> { type_is("GoogleTasksCredential") }, class_name: "Credential", inverse_of: :user
  has_one :microsoft_graph_credential, -> { type_is("MicrosoftGraphCredential") }, class_name: "Credential", inverse_of: :user
  has_one :http_header_credential, -> { type_is("HttpHeaderCredential") }, class_name: "Credential", inverse_of: :user

  belongs_to :last_cancelled_message, class_name: "Message", optional: true

  validates :first_name, presence: true
  validates :last_name, presence: true, on: :create, unless: :creating_google_credential?

  accepts_nested_attributes_for :credentials
  serialize :preferences, coder: JsonSerializer

  def preferences
    attributes["preferences"].with_defaults(dark_mode: "system")
  end

  private

  def creating_google_credential?
    return false unless credential = credentials.first

    !credential.persisted? && credential.type == "GoogleCredential"
  end
end

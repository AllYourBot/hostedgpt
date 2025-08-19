class User < ApplicationRecord
  include Personable, Registerable

  has_secure_password validations: false
  has_person_name

  # Profile picture attachment
  has_one_attached :profile_picture do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [50, 50], preprocessed: true
    attachable.variant :small, resize_to_limit: [100, 100], preprocessed: true
    attachable.variant :medium, resize_to_limit: [200, 200], preprocessed: true
  end

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

  # Profile picture validations
  validate :profile_picture_validation

  accepts_nested_attributes_for :credentials
  serialize :preferences, coder: JsonSerializer

  def preferences
    attributes["preferences"].with_defaults(dark_mode: "system")
  end

  # Profile picture helper methods
  def has_profile_picture?
    profile_picture.attached?
  end

  def profile_picture_url(variant = :small)
    return nil unless has_profile_picture?

    if Rails.application.config.x.app_url.blank?
      # For development/test environments without configured app URL
      Rails.application.routes.url_helpers.rails_blob_url(profile_picture.variant(variant), only_path: true)
    else
      profile_picture.variant(variant).url
    end
  end

  # Virtual attribute for removing profile picture
  def remove_profile_picture=(value)
    if value.to_s == '1' && profile_picture.attached?
      profile_picture.purge
    end
  end

  private

  def profile_picture_validation
    return unless profile_picture.attached?

    # Validate content type
    unless profile_picture.content_type.in?(%w[image/jpeg image/jpg image/png image/gif image/webp])
      errors.add(:profile_picture, "must be a valid image format (JPEG, PNG, GIF, or WebP)")
    end

    # Validate file size
    if profile_picture.byte_size > 5.megabytes
      errors.add(:profile_picture, "must be less than 5MB")
    end
  end

  def creating_google_credential?
    return false unless credential = credentials.first

    !credential.persisted? && credential.type == "GoogleCredential"
  end
end

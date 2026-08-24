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
  store_accessor :preferences, :dark_mode, :nav_closed

  def preferences
    attributes["preferences"] || {}
  end

  def dark_mode
    super.presence || "system"
  end

  def nav_closed=(value)
    super(value.nil? ? nil : value.to_b)
  end

  def features
    User::Features.new(self)
  end

  def ai_backend(driver)
    features[:"#{driver}_ai_backend"]
  end

  # @todo: generalize into a per-flag opinion API if other features ever need per-user values (#740)
  def ruby_llm?(driver)
    ai_backend(driver).presence || use_ruby_llm?
  end

  # Profile picture helper methods
  def has_profile_picture?
    profile_picture.attached?
  end

  def profile_picture_url(variant = :small)
    return nil unless has_profile_picture?
    return nil unless profile_picture.variable? # e.g. a rejected non-image upload still attached in memory

    # Always route through rails_blob_url rather than calling profile_picture.variant(variant).url directly:
    # the latter needs the variant to already be processed (a VariantRecord to exist), which only happens once
    # the async preprocessing job runs, so it returns nil for a freshly-uploaded picture. rails_blob_url resolves
    # to the representation redirect route, which transforms on demand and works immediately either way.
    url_options = Rails.application.config.x.app_url.present? ? {
      protocol: Rails.application.config.x.app_url_protocol,
      host: Rails.application.config.x.app_url_host,
      port: Rails.application.config.x.app_url_port,
    } : { only_path: true } # development/test environments without a configured app URL

    Rails.application.routes.url_helpers.rails_blob_url(profile_picture.variant(variant), **url_options)
  end

  # Virtual attribute for removing profile picture
  def remove_profile_picture=(value)
    if value.to_s == "1" && profile_picture.attached?
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

  def use_ruby_llm?
    Feature.raw_features.key?(:use_ruby_llm) ? Feature.use_ruby_llm? : false
  end
end

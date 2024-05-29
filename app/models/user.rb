class User < ApplicationRecord
  include Personable, Registerable
  encrypts :openai_key, :anthropic_key

  has_secure_password validations: false
  has_person_name

  validates :password, presence: true, on: :create, if: -> { auth_uid.blank? }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :first_name, presence: true
  validates :last_name, presence: true, on: :create

  has_many :assistants, -> { not_deleted }
  has_many :assistants_including_deleted, class_name: "Assistant", dependent: :destroy
  has_many :language_models, -> { not_deleted }
  has_many :language_models_including_deleted, class_name: "LanguageModel", dependent: :destroy
  has_many :conversations, dependent: :destroy
  belongs_to :last_cancelled_message, class_name: "Message", optional: true

  serialize :preferences, coder: JsonSerializer

  def preferences
    attributes["preferences"].with_defaults(dark_mode: "system")
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
end

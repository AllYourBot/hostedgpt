class User < ApplicationRecord
  include Personable, Registerable
  encrypts :openai_key, :anthropic_key

  has_secure_password
  has_person_name

  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :first_name, presence: true
  validates :last_name, presence: true, on: :create

  has_many :assistants, -> { not_deleted }
  has_many :assistants_including_deleted, class_name: "Assistant", dependent: :destroy
  has_many :conversations, dependent: :destroy
  belongs_to :last_cancelled_message, class_name: "Message", optional: true

  serialize :preferences, coder: JsonSerializer

  before_create :set_default_preferences

  private

  def set_default_preferences
    self.preferences ||= {}
    self.preferences[:dark_mode] ||= 'system'
  end
end

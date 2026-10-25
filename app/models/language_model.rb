# We don"t care about large or not
class LanguageModel < ApplicationRecord
  include Export

  # Claude models that take adaptive thinking on the Anthropic API.
  ADAPTIVE_THINKING_PREFIXES = %w[
    claude-opus-4-6 claude-sonnet-4-6 claude-opus-4-7 claude-opus-4-8
    claude-opus-5 claude-sonnet-5 claude-haiku-5 claude-fable-5
  ].freeze

  REASONING_SUMMARY_PREFIXES = {
    openai: %w[gpt-5 o1 o3 o4],
    gemini: %w[gemini-2.5 gemini-3],
  }.freeze

  def self.adaptive_thinking?(api_name)
    api_name.to_s.start_with?(*ADAPTIVE_THINKING_PREFIXES)
  end

  def self.supports_thinking?(provider, api_name)
    return adaptive_thinking?(api_name) if provider.to_s == "anthropic"

    REASONING_SUMMARY_PREFIXES.fetch(provider.to_sym, []).any? { |prefix| api_name.to_s.start_with?(prefix) }
  end

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
  delegate :name, to: :api_service, prefix: true, allow_nil: true

  def created_by_current_user?
    user == Current.user
  end

  def supports_tools?
    # The identity's policy owns the provider policy (Groq's denial, say),
    # regardless of whether the SDK or RubyLLM transport serves the request.
    attributes["supports_tools"] && AIBackend::Policy.for_identity(api_service.provider_identity)&.supports_tools?
  end

  def logo_filename
    api_service.logo_filename
  end

  def test(api_name = nil)
    ai_backend.test_language_model(self, api_name)
  end

  private

  def populate_position
    self.position = (user&.language_models&.maximum(:position) || 0) + 1
  end

  def soft_delete_assistants
    assistants.update_all(deleted_at: Time.current)
  end

end

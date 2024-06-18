module Credential::GoogleApp
  extend ActiveSupport::Concern

  included do
    alias_attribute :oauth_id, :external_id

    validates :oauth_token, presence: true
    validates :oauth_refresh_token, presence: true
    validates :oauth_id, presence: true, uniqueness: true
    validates :oauth_email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

    normalizes :oauth_email, with: -> email { email.downcase.strip }
  end

  def permissions
    properties.dig(:scope)&.split&.map { |p| p.split('/').last } || []
  end

  def has_permission?(perm)
    missing_permissions = Array(perm) - permissions
    missing_permissions.empty?
  end
end

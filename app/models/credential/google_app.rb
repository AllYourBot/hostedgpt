module Credential::GoogleApp
  extend ActiveSupport::Concern

  included do
    alias_attribute :oauth_id, :external_id

    validates :oauth_token, presence: true
    validates :oauth_refresh_token, presence: true
    validates :oauth_id, presence: true, uniqueness: { scope: :user_id }
    validates :oauth_email, presence: true, uniqueness: { scope: :user_id }, format: { with: URI::MailTo::EMAIL_REGEXP }

    normalizes :oauth_email, with: -> email { email.downcase.strip }

    store_accessor :properties, :scope
  end

  def permissions = scope&.split&.map { it.split("/").last } || []

  def has_permission?(perm)
    missing_permissions = Array(perm) - permissions
    missing_permissions.empty?
  end
end

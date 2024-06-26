class Credential < ApplicationRecord
  belongs_to :user

  has_many :authentications, -> { not_deleted }
  has_many :authentications_including_deleted, class_name: "Authentication", inverse_of: :credential, dependent: :destroy

  encrypts :external_id, :oauth_email, :oauth_token, :oauth_refresh_token, deterministic: true

  serialize :properties, coder: JsonSerializer
end

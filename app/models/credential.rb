class Credential < ApplicationRecord
  belongs_to :user
  encrypts :external_id, :oauth_email, :oauth_token, :oauth_refresh_token, deterministic: true

  has_many :authentications, -> { not_deleted }
  has_many :authentications_including_deleted, class_name: "Authentication", inverse_of: :credential, dependent: :destroy

  serialize :properties, coder: JsonSerializer
end

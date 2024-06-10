class PasswordCredential < Credential
  has_secure_password validations: false

  validates :password, presence: true, on: :create
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
end

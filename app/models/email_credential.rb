class EmailCredential < Credential
  has_secure_password validations: false

  validates :password, presence: true, on: :create, if: -> { auth_uid.blank? }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: -> email { email.downcase.strip }
end

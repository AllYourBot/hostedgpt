class User < ApplicationRecord
  include Personable, Registerable

  has_secure_password

  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :first_name, :last_name, presence: true, on: :create

  has_many :assistants, dependent: :destroy
  has_many :conversations, dependent: :destroy
end

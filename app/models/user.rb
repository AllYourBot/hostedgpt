class User < ApplicationRecord
  include Personable, Registerable

  has_secure_password
  has_person_name

  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :first_name, presence: true
  validates :last_name, presence: true, on: :create

  has_many :assistants, dependent: :destroy
  has_many :conversations, dependent: :destroy

  serialize :preferences, coder: JsonSerializer
end

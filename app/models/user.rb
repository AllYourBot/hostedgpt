class User < ApplicationRecord
  include Personable

  has_secure_password

  validates :password, presence: true
  validates :password_confirmation, presence: true
end

class User < ApplicationRecord
  include Personable

  has_secure_password

  validates :password, presence: true, on: :create
  validates :password_confirmation, presence: true, on: :create

  has_many :chats, dependent: :destroy
end

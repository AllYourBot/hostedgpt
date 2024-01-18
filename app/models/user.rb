class User < ApplicationRecord
  include Personable, Registerable

  has_secure_password

  validates :password, presence: true, on: :create, length: { minimum: 6 }

  has_many :chats, dependent: :destroy
  has_many :assistants, dependent: :destroy
  has_many :conversations, dependent: :destroy

  after_create_commit :create_blank_chat

  private

  def create_blank_chat
    chats.create!(name: "HostedGPT")
  end
end

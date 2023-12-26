class Conversation < ApplicationRecord
  belongs_to :user
  belongs_to :assistant

  has_many :messages, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
end

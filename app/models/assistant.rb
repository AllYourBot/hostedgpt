class Assistant < ApplicationRecord
  belongs_to :user

  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
  has_many :messages, through: :conversations

  validates :tools, presence: true, allow_blank: true
end

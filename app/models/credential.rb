class Credential < ApplicationRecord
  belongs_to :user

  has_many :authentications, dependent: :destroy

  serialize :properties, coder: JsonSerializer
end

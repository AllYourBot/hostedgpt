class Credential < ApplicationRecord
  belongs_to :user

  has_many :authentications, -> { not_deleted }
  has_many :authentications_including_deleted, class_name: "Authentication", inverse_of: :credential, dependent: :destroy

  serialize :properties, coder: JsonSerializer
end

class Collection < ApplicationRecord
  MAX_LIST_DISPLAY = 3

  belongs_to :user

  has_many :documents, dependent: :destroy

  scope :ordered, -> { order(:name) }

  validates :name, presence: true
end

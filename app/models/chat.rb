class Chat < ApplicationRecord
  belongs_to :user
  has_many :notes, dependent: :destroy
  broadcasts_refreshes
end

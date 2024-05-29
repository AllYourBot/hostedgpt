class Authentication < ApplicationRecord
  belongs_to :user
  belongs_to :credential

  scope :active, -> { not_ended }
end

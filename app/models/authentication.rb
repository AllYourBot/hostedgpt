class Authentication < ApplicationRecord
  belongs_to :user
  belongs_to :credential
end

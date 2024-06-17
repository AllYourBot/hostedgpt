class Authentication < ApplicationRecord
  belongs_to :credential
  belongs_to :client
end

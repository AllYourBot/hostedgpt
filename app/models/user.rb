class User < ApplicationRecord
  has_secure_password

  include Personable
end

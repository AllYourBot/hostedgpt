class Client < ApplicationRecord
  include TimeZoneable

  belongs_to :person

  has_one :authentication, -> { not_deleted }
  has_many :authentications_including_deleted, class_name: "Authentication", inverse_of: :client, dependent: :destroy

  enum platform: %w[ ios android web api ].index_by(&:to_sym)

  has_secure_token

  scope :ordered, -> { order(updated_at: :asc) }

  def authenticated?
    authentication.present? && authentication.persisted?
  end

  def authenticate_with!(credential)
    if authentication
      authentication&.deleted!
      reload_authentication
    end
    create_authentication! credential: credential
  end

  def logout!
    return false unless authenticated?
    authentication.deleted!
    reload_authentication
    true
  end

  def to_s
    token
  end
end

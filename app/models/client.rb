class Client < ApplicationRecord
  include TimeZoneable

  belongs_to :person

  has_one :authentication, -> { active }
  has_many :authentications_including_inactive, class_name: "Authentication", inverse_of: :client, dependent: :destroy

  enum platform: %w[ ios android web api tool ].index_by(&:to_sym)
  enum format: %w[ desktop phone tablet tv unknown ].index_by(&:to_sym)

  has_secure_token

  scope :ordered, -> { order(updated_at: :asc) }

  def authenticated?
    authentication.present?
  end

  def logout!
    return false if authentication.blank?
    authentication.update!(ended_at: Time.current)
    reload_authentication
    true
  end

  def to_s
    token
  end
end

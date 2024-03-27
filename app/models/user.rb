class User < ApplicationRecord
  include Personable, Registerable

  has_secure_password
  has_person_name

  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :first_name, presence: true
  validates :last_name, presence: true, on: :create

  has_many :assistants, dependent: :destroy
  has_many :conversations, dependent: :destroy

  serialize :preferences, coder: JsonSerializer

  def full_name
    "#{first_name} #{last_name}".strip.presence
  end

  def initials
    return nil if first_name.blank?

    [first_name, last_name]
      .reject(&:blank?)
      .map { |name| name[0].capitalize }
      .join
  end
end

# == Schema Information
#
# Table name: users
#
#  id                        :bigint           not null, primary key
#  anthropic_key             :string
#  first_name                :string           not null
#  last_name                 :string
#  openai_key                :string
#  password_digest           :string
#  preferences               :jsonb
#  registered_at             :datetime
#  last_cancelled_message_id :bigint
#
# Indexes
#
#  index_users_on_last_cancelled_message_id  (last_cancelled_message_id)
#
# Foreign Keys
#
#  fk_rails_...  (last_cancelled_message_id => messages.id)
#
class User < ApplicationRecord
  include Personable, Registerable
  encrypts :openai_key, :anthropic_key

  has_secure_password
  has_person_name

  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :first_name, presence: true
  validates :last_name, presence: true, on: :create

  has_many :assistants, dependent: :destroy
  has_many :conversations, dependent: :destroy
  belongs_to :last_cancelled_message, class_name: "Message", optional: true

  serialize :preferences, coder: JsonSerializer

  def preferences
    attributes["preferences"].with_defaults(dark_mode: "system")
  end
end

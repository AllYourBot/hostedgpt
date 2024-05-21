# == Schema Information
#
# Table name: assistants
#
#  id                                                      :bigint           not null, primary key
#  description                                             :string
#  images                                                  :boolean          default(FALSE), not null
#  instructions                                            :string
#  model                                                   :string
#  name                                                    :string
#  tools                                                   :jsonb            not null
#  created_at                                              :datetime         not null
#  updated_at                                              :datetime         not null
#  external_id(The Backend AI's (e.g OpenAI) assistant id) :text
#  user_id                                                 :bigint           not null
#
# Indexes
#
#  index_assistants_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Assistant < ApplicationRecord
  belongs_to :user

  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
  has_many :messages # TODO: What should happen if an assistant is deleted?

  validates :tools, presence: true, allow_blank: true

  scope :ordered, -> { order(:id) }

  def initials
    return nil if name.blank?

    parts = name.split(/[\- ]/)

    parts[0][0].capitalize +
      parts[1]&.try(:[], 0)&.capitalize.to_s
  end

  def to_s
    name
  end
end

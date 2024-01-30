class Conversation < ApplicationRecord
  belongs_to :user
  belongs_to :assistant

  has_many :messages, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy

  after_create_commit :set_title_async, if: -> { title.blank? }


  private

  def set_title_async
    AutotitleConversationJob.perform_later(id)
  end
end

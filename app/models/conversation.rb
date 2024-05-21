# == Schema Information
#
# Table name: conversations
#
#  id                                                        :bigint           not null, primary key
#  title                                                     :string
#  created_at                                                :datetime         not null
#  updated_at                                                :datetime         not null
#  assistant_id                                              :bigint           not null
#  external_id(The Backend AI system (e.g OpenAI) Thread Id) :text
#  last_assistant_message_id                                 :bigint
#  user_id                                                   :bigint           not null
#
# Indexes
#
#  index_conversations_on_assistant_id               (assistant_id)
#  index_conversations_on_last_assistant_message_id  (last_assistant_message_id)
#  index_conversations_on_updated_at                 (updated_at)
#  index_conversations_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (assistant_id => assistants.id)
#  fk_rails_...  (last_assistant_message_id => messages.id)
#  fk_rails_...  (user_id => users.id)

class Conversation < ApplicationRecord
  include Version

  belongs_to :user
  belongs_to :assistant

  has_many :messages, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
  belongs_to :last_assistant_message, class_name: "Message", optional: true

  after_touch :set_title_async, if: -> { title.blank? && messages.count >= 2 }

  scope :ordered, -> { order(updated_at: :desc) }

  broadcasts_refreshes

  # Builds a hash of date interval keys and queries which fetch the records for that internal.
  #
  # Empty intervals are removed from the hash.
  #
  # {
  #  "Today" => relation,
  #  "Yesterday" => relation,
  #  "This Week" => relation,
  #  "This Month" => relation,
  #  "Last Month" => relation,
  #  "Older" => relation
  # }
  def self.grouped_by_increasing_time_interval_for_user(user)
    nav_conversations = user.conversations.ordered

    keys = ["Today", "Yesterday", "This Week", "This Month", "Last Month", "Older"]
    values = [
      nil,
      Date.today.beginning_of_day,
      (Date.today - 1.day).beginning_of_day,
      (Date.today - 1.week).beginning_of_day,
      (Date.today - 1.month).beginning_of_day,
      (Date.today - 2.months).beginning_of_day,
      nil
    ].each_cons(2).map do |range_start, range_end|
      range = case
      when range_start.nil?
        range_end..
      when range_end.nil?
        ..range_start
      else
        range_end..range_start
      end

      nav_conversations.where(updated_at: range)
    end

    keys.zip(values)
      .to_h
      .delete_if { |_, v| v.empty? }
  end

  private

  def set_title_async
    AutotitleConversationJob.perform_later(id)
  end
end

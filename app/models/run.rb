# == Schema Information
#
# Table name: runs
#
#  id                                                     :bigint           not null, primary key
#  additional_instructions                                :string
#  cancelled_at                                           :datetime
#  completed_at                                           :datetime
#  expired_at                                             :datetime         not null
#  failed_at                                              :datetime
#  file_ids                                               :jsonb            not null
#  instructions                                           :string
#  last_error                                             :jsonb
#  model                                                  :string           not null
#  required_action                                        :jsonb
#  started_at                                             :datetime
#  status                                                 :string           not null
#  tools                                                  :jsonb            not null
#  created_at                                             :datetime         not null
#  updated_at                                             :datetime         not null
#  assistant_id                                           :bigint           not null
#  conversation_id                                        :bigint           not null
#  external_id(The Backend AI system (e.g OpenAI) Run Id) :text
#
# Indexes
#
#  index_runs_on_assistant_id     (assistant_id)
#  index_runs_on_conversation_id  (conversation_id)
#
# Foreign Keys
#
#  fk_rails_...  (assistant_id => assistants.id)
#  fk_rails_...  (conversation_id => conversations.id)
#

class Run < ApplicationRecord
  belongs_to :assistant
  belongs_to :conversation

  has_many :steps, dependent: :destroy
  has_one :message, dependent: :nullify

  enum status: %w[queued in_progress requires_action cancelling cancelled failed completed expired].index_by(&:to_sym)

  validates :status, :expired_at, :model, :instructions, presence: true
  validates :tools, :file_ids, presence: true, allow_blank: true
end

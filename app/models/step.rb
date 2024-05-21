# == Schema Information
#
# Table name: steps
#
#  id                                                      :bigint           not null, primary key
#  cancelled_at                                            :datetime
#  completed_at                                            :datetime
#  details                                                 :jsonb            not null
#  expired_at                                              :datetime
#  failed_at                                               :datetime
#  kind                                                    :string           not null
#  last_error                                              :jsonb
#  status                                                  :string           not null
#  created_at                                              :datetime         not null
#  updated_at                                              :datetime         not null
#  assistant_id                                            :bigint           not null
#  conversation_id                                         :bigint           not null
#  external_id(The Backend AI system (e.g OpenAI) Step Id) :text
#  run_id                                                  :bigint           not null
#
# Indexes
#
#  index_steps_on_assistant_id     (assistant_id)
#  index_steps_on_conversation_id  (conversation_id)
#  index_steps_on_run_id           (run_id)
#
# Foreign Keys
#
#  fk_rails_...  (assistant_id => assistants.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (run_id => runs.id)
#

class Step < ApplicationRecord
  belongs_to :assistant
  belongs_to :conversation
  belongs_to :run

  enum kind: %w[message_creation tool_calls].index_by(&:to_sym)
  enum status: %w[in_progress cancelled failed completed expired].index_by(&:to_sym)

  validates :kind, :status, presence: true
  validates :details, presence: true, allow_blank: true
end

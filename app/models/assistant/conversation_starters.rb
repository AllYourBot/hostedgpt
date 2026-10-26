module Assistant::ConversationStarters
  extend ActiveSupport::Concern

  MAX_CONVERSATION_STARTERS = 4

  included do
    # The settings form posts a field for every starter, so the ones left empty are dropped.
    normalizes :conversation_starters, with: ->(starters) { Array(starters).map { |starter| starter.to_s.strip }.compact_blank }
    validates :conversation_starters, length: { maximum: MAX_CONVERSATION_STARTERS }
  end
end

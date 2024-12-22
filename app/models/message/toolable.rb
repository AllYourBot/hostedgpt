module Message::Toolable
  extend ActiveSupport::Concern

  included do
    has_many :memories, dependent: :nullify

    serialize :content_tool_calls, coder: JsonSerializer

    validates :tool_call_id, presence: true, if: :tool?
    validates :content_tool_calls, presence: true, if: :tool?

    normalizes :tool_call_id, with: -> tool_call_id { tool_call_id[0...40] }
  end

  def only_tool_response?
    tool? || (content_tool_calls.present? && content_text.blank?)
  end

  def tool_related?
    only_tool_response? || content_tool_calls.present?
  end
end

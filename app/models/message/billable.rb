module Message::Billable
  extend ActiveSupport::Concern
  included do
    attribute :input_token_count, :integer, default: 0
    attribute :output_token_count, :integer, default: 0

    rollup_cache :input_token_total_count, sum: :input_token_count, belongs_to: :conversation
    rollup_cache :output_token_total_count, sum: :output_token_count, belongs_to: :conversation

    attribute :input_token_cost, :decimal, precision: 10, scale: 2, default: 0.0
    attribute :output_token_cost, :decimal, precision: 10, scale: 2, default: 0.0

    rollup_cache :input_token_total_cost, sum: :input_token_cost, belongs_to: :conversation
    rollup_cache :output_token_total_cost, sum: :output_token_cost, belongs_to: :conversation
  end
end

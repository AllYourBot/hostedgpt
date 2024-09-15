module Conversation::Billable
  extend ActiveSupport::Concern
  included do
    # attribute :input_token_total_count, :integer, default: 0
    # attribute :output_token_total_count, :integer, default: 0

    # attribute :input_token_total_cost, :float, precision: 30, scale: 15, default: "0.0"
    # attribute :output_token_total_cost, :float, precision: 30, scale: 15, default: "0.0"
  end
end

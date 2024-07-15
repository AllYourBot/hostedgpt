module Message::TokenCount
  extend ActiveSupport::Concern
  included do
    attribute :input_token_count, :integer, default: 0
    attribute :output_token_count, :integer, default: 0
  end
end

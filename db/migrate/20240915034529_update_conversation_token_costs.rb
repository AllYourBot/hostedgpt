class UpdateConversationTokenCosts < ActiveRecord::Migration[7.1]
  def change
    change_column :conversations, :input_token_total_cost, :decimal, precision: 30, scale: 15, default: 0.0, null: false
    change_column :conversations, :output_token_total_cost, :decimal, precision: 30, scale: 15, default: 0.0, null: false
  end
end

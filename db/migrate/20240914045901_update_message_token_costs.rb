class UpdateMessageTokenCosts < ActiveRecord::Migration[7.1]
  def change
    change_column :messages, :input_token_cost_cents, :decimal, precision: 30, scale: 15, default: 0.0, null: false
    change_column :messages, :output_token_cost_cents, :decimal, precision: 30, scale: 15, default: 0.0, null: false
  end
end

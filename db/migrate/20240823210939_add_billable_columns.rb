class AddBillableColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :input_token_cost, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :messages, :output_token_cost, :decimal, precision: 10, scale: 2, default: 0.0, null: false

    add_column :conversations, :input_token_total_cost, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :conversations, :output_token_total_cost, :decimal, precision: 10, scale: 2, default: 0.0, null: false

    add_column :conversations, :input_token_total_count, :integer, default: 0, null: false
    add_column :conversations, :output_token_total_count, :integer, default: 0, null: false
  end
end

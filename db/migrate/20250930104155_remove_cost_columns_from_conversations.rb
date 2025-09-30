class RemoveCostColumnsFromConversations < ActiveRecord::Migration[8.0]
  def change
    remove_column :conversations, :input_token_total_cost, :decimal
    remove_column :conversations, :output_token_total_cost, :decimal
  end
end

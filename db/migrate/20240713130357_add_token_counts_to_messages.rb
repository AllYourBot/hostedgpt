class AddTokenCountsToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :input_token_count, :integer, default: 0, null: false
    add_column :messages, :output_token_count, :integer, default: 0, null: false
  end
end

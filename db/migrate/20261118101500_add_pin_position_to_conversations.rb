class AddPinPositionToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :pin_position, :integer
    add_index :conversations, [:user_id, :pin_position]
  end
end

class AddIndexOnUpdatedAtToConversations < ActiveRecord::Migration[7.1]
  def change
    add_index :conversations, :updated_at
  end
end

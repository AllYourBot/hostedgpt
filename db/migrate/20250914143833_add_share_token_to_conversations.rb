class AddShareTokenToConversations < ActiveRecord::Migration[8.0]
  def change
    add_column :conversations, :share_token, :string
    add_index :conversations, :share_token
  end
end

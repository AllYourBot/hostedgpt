class AddUnreadToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :unread, :boolean, default: false, null: false
  end
end

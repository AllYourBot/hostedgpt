class AddDeletedAtToAssistants < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :deleted_at, :timestamp, default: nil
    add_index :assistants, [:user_id, :deleted_at]
  end
end

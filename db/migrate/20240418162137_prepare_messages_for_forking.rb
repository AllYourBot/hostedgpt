class PrepareMessagesForForking < ActiveRecord::Migration[7.1]
  def up
    add_column :messages, :branched, :boolean, default: false, null: false
    add_column :messages, :branched_from_version, :integer
    remove_column :messages, :rerequested_at
    add_index :messages, [:conversation_id, :index, :version], unique: true
  end

  def down
    remove_index :messages, column: [:conversation_id, :index, :version]
    remove_column :messages, :branched
    remove_column :messages, :branched_from_version
    add_column :messages, :rerequested_at, :datetime
  end
end

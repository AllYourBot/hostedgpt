class AddAssistantStartedAtToMessages < ActiveRecord::Migration[7.1]
  def change
    rename_column :messages, :rerequested_at, :assistant_rerequested_at
    rename_column :messages, :cancelled_at, :assistant_cancelled_at
    add_column :messages, :assistant_started_at, :timestamp
  end
end

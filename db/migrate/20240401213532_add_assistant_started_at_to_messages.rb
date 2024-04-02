class AddAssistantStartedAtToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :processed_at, :timestamp
  end
end

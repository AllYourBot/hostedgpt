class AddTruncatedAtToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :truncated_at, :datetime
  end
end

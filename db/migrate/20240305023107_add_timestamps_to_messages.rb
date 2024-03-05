class AddTimestampsToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :rerequested_at, :datetime
    add_column :messages, :cancelled_at, :datetime
  end
end

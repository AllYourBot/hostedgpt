class AddIndexOnCreatedAtToMessages < ActiveRecord::Migration[7.1]
  def change
    add_index :messages, :updated_at
  end
end

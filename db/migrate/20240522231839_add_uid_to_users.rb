class AddUidToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :auth_uid, :string
    add_index :users, :auth_uid, unique: true
  end
end
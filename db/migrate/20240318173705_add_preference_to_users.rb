class AddPreferenceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :preferences, :jsonb, null: false, default: {}
  end
end

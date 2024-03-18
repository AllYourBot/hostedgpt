class AddPreferenceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :preferences, :jsonb
  end
end

class SetDefaultPreferencesToEmptyHash < ActiveRecord::Migration[7.1]
  def up
    change_column :users, :preferences, :jsonb, default: {}
  end

  def down
    change_column :users, :preferences, :jsonb, default: nil
  end
end
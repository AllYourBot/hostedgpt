class AlterColumnInstructionsOnRunsToAllowNil < ActiveRecord::Migration[7.1]
  def change
    change_column :runs, :instructions, :string, null: true
  end
end

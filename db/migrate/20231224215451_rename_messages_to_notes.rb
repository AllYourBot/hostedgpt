class RenameMessagesToNotes < ActiveRecord::Migration[7.1]
  def change
    rename_table :messages, :notes
  end
end

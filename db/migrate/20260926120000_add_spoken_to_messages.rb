class AddSpokenToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :spoken, :boolean, default: false, null: false
  end
end

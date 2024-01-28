class AddPinnedAndCustomToAssistants < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :pinned, :boolean, null: false, default: false
    add_column :assistants, :custom, :boolean, null: false, default: false
  end
end

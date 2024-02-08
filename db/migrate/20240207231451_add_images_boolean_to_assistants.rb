class AddImagesBooleanToAssistants < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :images, :boolean, null: false, default: false
  end
end

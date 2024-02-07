class AddImagesBooleanToAssistants < ActiveRecord::Migration[7.1]
  def chage
    add_column :assistants, :images, :boolean, null: false, default: false
  end
end

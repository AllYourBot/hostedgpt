class AddExternalIdToAssistants < ActiveRecord::Migration[7.1]
  def up
    add_column :assistants, :external_id, :text, comment: "The Backend AI's (e.g OpenAI) assistant id"
  end
  def down
    remove_column :assistants, :external_id, :text
  end
end

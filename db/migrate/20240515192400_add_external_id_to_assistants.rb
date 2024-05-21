class AddExternalIdToAssistants < ActiveRecord::Migration[7.1]
  def up
    add_column :assistants, :external_id, :text, if_not_exists: true,  comment: "The Backend AI's (e.g OpenAI) assistant id"
    add_index  :assistants, :external_id, unique: true, if_not_exists: true
  end
  def down
    remove_index :assistants,  :external_id
    remove_column :assistants, :external_id, :text
  end
end

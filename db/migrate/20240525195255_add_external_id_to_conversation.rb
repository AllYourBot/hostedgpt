class AddExternalIdToConversation < ActiveRecord::Migration[7.1]
  def up
    add_column :conversations, :external_id, :text, if_not_exists: true,  comment: "The Backend AI system (e.g OpenAI) Thread Id"
    add_index  :conversations, :external_id, unique: true, if_not_exists: true
  end

  def down
    remove_index  :conversations, :external_id
    remove_column :conversations, :external_id, :text
  end
end

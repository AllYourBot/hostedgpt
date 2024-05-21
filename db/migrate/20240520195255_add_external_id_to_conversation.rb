class AddExternalIdToConversation < ActiveRecord::Migration[7.1]
  def up
    add_column :conversations, :external_id, :text, comment: "The Backend AI system (e.g OpenAI) Thread Id"
  end
  def down
    remove_column :conversations, :external_id, :text
  end
end

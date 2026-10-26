class AddConversationStartersToAssistants < ActiveRecord::Migration[8.1]
  def change
    add_column :assistants, :conversation_starters, :jsonb, default: [], null: false
  end
end

class ChangeColumnAssistantIdOnMessages < ActiveRecord::Migration[7.1]
  def up
    # Message.all.each { |m| m.update!(assistant: m.conversation.assistant) }
    change_column :messages, :assistant_id, :bigint, null: false
  end

  def down
    change_column :messages, :assistant_id, :bigint, null: true
  end
end

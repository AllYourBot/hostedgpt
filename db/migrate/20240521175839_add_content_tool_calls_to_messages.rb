class AddContentToolCallsToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :content_tool_calls, :jsonb
    add_column :messages, :tool_call_id, :string
  end
end

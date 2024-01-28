class AddAssistantIdToMessages < ActiveRecord::Migration[7.1]
  def change
    add_reference :messages, :assistant, null: true, foreign_key: true
  end
end

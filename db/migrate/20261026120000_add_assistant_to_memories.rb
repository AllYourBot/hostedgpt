class AddAssistantToMemories < ActiveRecord::Migration[8.1]
  def change
    add_reference :memories, :assistant, foreign_key: true
  end
end
